/*
Copyright 2016 Workiva Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
import 'dart:async';
import 'dart:html';
import 'package:font_face_observer/support.dart';
import 'package:font_face_observer/src/ruler.dart';
import 'package:font_face_observer/src/adobe_blank.dart';

const int DEFAULT_TIMEOUT = 3000;
const String DEFAULT_TEST_STRING = 'BESbswy';
const String _NORMAL = 'normal';
const int _NATIVE_FONT_LOADING_CHECK_INTERVAL = 50;

final Future<FontLoadResult> _adobeBlankLoadedFuture =
    (new FontFaceObserver(AdobeBlankFamily)).load(AdobeBlankFontBase64Url);

/// Simple container object for result data
class FontLoadResult {
  final bool isLoaded;
  final bool didTimeout;
  FontLoadResult({this.isLoaded: true, this.didTimeout: false});

  @override
  String toString() => 'FontLoadResult {isLoaded: $isLoaded, didTimeout: $didTimeout}';
}

// holds data about each loaded font
class _LoadedFont {
  final StyleElement element;
  final String group;
  int _uses = 0;
  _LoadedFont(this.element, {this.group: ""});

  int get uses => _uses;
  void set uses(int new_uses) {
    _uses = new_uses;
    element.attributes['uses'] = _uses.toString();
  }
}

class FontFaceObserver {
  String family;
  String style;
  String weight;
  String stretch;
  String _testString;
  int timeout;
  bool useSimulatedLoadEvents;
  String group;
  Completer _result = new Completer();

  /// A map of font key String to _LoadedFont
  static Map<String, _LoadedFont> _loadedFonts = new Map<String, _LoadedFont>();

  FontFaceObserver(String this.family,
      {String this.style: _NORMAL,
      String this.weight: _NORMAL,
      String this.stretch: _NORMAL,
      String testString: DEFAULT_TEST_STRING,
      int this.timeout: DEFAULT_TIMEOUT,
      bool this.useSimulatedLoadEvents: false,
      String this.group: ""}) {
    this.testString = testString;
    if (family != null) {
      family = family.trim();
      bool hasStartQuote = family.startsWith('"') || family.startsWith("'");
      bool hasEndQuote = family.endsWith('"') || family.endsWith("'");
      if (hasStartQuote && hasEndQuote) {
        family = family.substring(1, family.length - 1);
      }
      if (group == null) {
        group = "";
      }
    }
  }

  String get key => '${family}_${style}_${weight}_${stretch}';

  String get testString => _testString;

  _LoadedFont _getLoadedFont(String url) {
    var styleElement;
    String _key = key;
    _LoadedFont loadedFont;
    if (_loadedFonts.containsKey(_key)) {
      loadedFont = _loadedFonts[_key];
    } else {
      var rule = '''
      @font-face {
        font-family: "${family}";
        font-style: ${style};
        font-weight: ${weight};
        src: url(${url});
      }''';
      styleElement = new StyleElement()
        ..className = '_ffo'
        ..text = rule
        ..attributes['key'] = _key;
      if (group != null && group.length > 0) {
        styleElement.attributes['group'] = group;
      }
      loadedFont = new _LoadedFont(styleElement, group: group);
      _loadedFonts[_key] = loadedFont;
      document.head.append(styleElement);
    }
    return loadedFont;
  }

  set testString(String newTestString) {
    this._testString = newTestString;
    if (_testString == null) {
      _testString = DEFAULT_TEST_STRING;
    }
    _testString = _testString.trim();
    if (_testString.length == 0) {
      _testString = DEFAULT_TEST_STRING;
    }
  }

  String _getStyle(String family, {cssSize: '100px'}) {
    var _stretch = SUPPORTS_STRETCH ? stretch : '';
    return '$style $weight $_stretch $cssSize $family';
  }

  /// This gets called when the timeout has been reached.
  /// It will cancel the passed in Timer if it is still active and
  /// complete the result with a timed out FontLoadResult
  void _onTimeout(Timer t) {
    if (t != null && t.isActive) {
      t.cancel();
    }
    if (!_result.isCompleted) {
      _result.complete(new FontLoadResult(isLoaded: false, didTimeout: true));
    }
  }

  _periodicallyCheckDocumentFonts(Timer t) {
    if (document.fonts.check(_getStyle('"$family"'), testString)) {
      t.cancel();
      _result.complete(new FontLoadResult(isLoaded: true, didTimeout: false));
    }
  }

  /// Wait for the font face represented by this FontFaceObserver to become
  /// available in the browser. It will asynchronously return a FontLoadResult
  /// with the result of whether or not the font is loaded or the timeout was
  /// reached while waiting for it to become available.
  Future<FontLoadResult> check() async {
    Timer t;
    if (_result.isCompleted) {
      return _result.future;
    }

    if (family != AdobeBlankFamily) {
      await _adobeBlankLoadedFuture;
    }

    // if the browser supports FontFace API set up an interval to check if
    // the font is loaded
    if (SUPPORTS_NATIVE_FONT_LOADING && !useSimulatedLoadEvents) {
      t = new Timer.periodic(
          new Duration(milliseconds: _NATIVE_FONT_LOADING_CHECK_INTERVAL), _periodicallyCheckDocumentFonts);
    } else {
      t = _simulateFontLoadEvents();
    }

    // Start a timeout timer that will cancel everything and complete
    // our _loaded future with false if it isn't already completed
    new Timer(new Duration(milliseconds: timeout), () => _onTimeout(t));

    return _result.future;
  }

  Timer _simulateFontLoadEvents() {
    var _rulerSansSerif = new Ruler(testString);
    var _rulerSerif = new Ruler(testString);
    var _rulerMonospace = new Ruler(testString);

    var widthSansSerif = -1;
    var widthSerif = -1;
    var widthMonospace = -1;

    var fallbackWidthSansSerif = -1;
    var fallbackWidthSerif = -1;
    var fallbackWidthMonospace = -1;

    var container = document.createElement('div');

    // Internal check function
    // -----------------------
    // If metric compatible fonts are detected, one of the widths will be -1. This is
    // because a metric compatible font won't trigger a scroll event. We work around
    // this by considering a font loaded if at least two of the widths are the same.
    // Because we have three widths, this still prevents false positives.
    //
    // Cases:
    // 1) Font loads: both a, b and c are called and have the same value.
    // 2) Font fails to load: resize callback is never called and timeout happens.
    // 3) WebKit bug: both a, b and c are called and have the same value, but the
    //    values are equal to one of the last resort fonts, we ignore this and
    //    continue waiting until we get new values (or a timeout).
    _checkWidths() {
      if ((widthSansSerif != -1 && widthSerif != -1) ||
          (widthSansSerif != -1 && widthMonospace != -1) ||
          (widthSerif != -1 && widthMonospace != -1)) {
        if (widthSansSerif == widthSerif || widthSansSerif == widthMonospace || widthSerif == widthMonospace) {
          // All values are the same, so the browser has most likely loaded the web font
          if (HAS_WEBKIT_FALLBACK_BUG) {
            // Except if the browser has the WebKit fallback bug, in which case we check to see if all
            // values are set to one of the last resort fonts.

            if (((widthSansSerif == fallbackWidthSansSerif &&
                    widthSerif == fallbackWidthSansSerif &&
                    widthMonospace == fallbackWidthSansSerif) ||
                (widthSansSerif == fallbackWidthSerif &&
                    widthSerif == fallbackWidthSerif &&
                    widthMonospace == fallbackWidthSerif) ||
                (widthSansSerif == fallbackWidthMonospace &&
                    widthSerif == fallbackWidthMonospace &&
                    widthMonospace == fallbackWidthMonospace))) {
              // The width we got matches some of the known last resort fonts, so let's assume we're dealing with the last resort font.
              return;
            }
          }
          if (container != null) {
            container.remove();
          }
          if (!_result.isCompleted) {
            _result.complete(new FontLoadResult(isLoaded: true, didTimeout: false));
          }
        }
      }
    }

    // This ensures the scroll direction is correct.
    container.dir = 'ltr';
    container.className = 'font_face_container';
    _rulerSansSerif.setFont(_getStyle('sans-serif'));
    _rulerSerif.setFont(_getStyle('serif'));
    _rulerMonospace.setFont(_getStyle('monospace'));

    container.append(_rulerSansSerif.element);
    container.append(_rulerSerif.element);
    container.append(_rulerMonospace.element);

    document.body.append(container);

    fallbackWidthSansSerif = _rulerSansSerif.getWidth();
    fallbackWidthSerif = _rulerSerif.getWidth();
    fallbackWidthMonospace = _rulerMonospace.getWidth();

    _rulerSansSerif.onResize((width) {
      widthSansSerif = width;
      _checkWidths();
    });

    _rulerSansSerif.setFont(_getStyle('"$family",AdobeBlank,sans-serif'));

    _rulerSerif.onResize((width) {
      widthSerif = width;
      _checkWidths();
    });

    _rulerSerif.setFont(_getStyle('"$family",AdobeBlank,serif'));

    _rulerMonospace.onResize((width) {
      widthMonospace = width;
      _checkWidths();
    });

    _rulerMonospace.setFont(_getStyle('"$family",AdobeBlank,monospace'));

    // The above code will trigger a scroll event when the font loads
    // but if the document is hidden, it may not, so we will periodically
    // check for changes in the rulers if the document is hidden
    return new Timer.periodic(new Duration(milliseconds: 50), (Timer t) {
      if (document.hidden) {
        widthSansSerif = _rulerSansSerif.getWidth();
        widthSerif = _rulerSerif.getWidth();
        widthMonospace = _rulerMonospace.getWidth();
        _checkWidths();
      }
    });
  }

  /// Load the font into the browser given a url that could be a network url
  /// or a pre-built data or blob url.
  Future<FontLoadResult> load(String url) async {
    if (_result.isCompleted) {
      // TODO increment uses count here?
      return _result.future;
    }
    _LoadedFont loadedFont = _getLoadedFont(url);
    loadedFont.uses++;

    // Since browsers may not load a font until it is actually used
    // We add this span to trigger the browser to load the font when used
    SpanElement dummy = new SpanElement()
      ..className = '$fontFaceObserverTempClassname ffo_dummy'
      ..setAttribute('style', 'font-family: "${family}"; visibility: hidden;')
      ..text = testString;

    document.body.append(dummy);
    var isLoadedFuture = check();
    _removeElementWhenComplete(isLoadedFuture, dummy);
    return isLoadedFuture;
  }

  _removeElementWhenComplete(Future f, HtmlElement el) async {
    f.whenComplete(() => el.remove());
  }

  bool get isLoaded {
    var loadedFont = _loadedFonts[key];
    return loadedFont != null && loadedFont.uses > 0;
  }

  static int unloadGroup(String group) {
    if (group == null) {
      group = "";
    }
    var keysToRemove = [];
    _loadedFonts.keys.forEach((k) {
      var loadedFont = _loadedFonts[k];
      if (loadedFont.group == group || (group == "" && loadedFont.group == null)) {
        keysToRemove.add(k);
      }
    });
    keysToRemove.forEach(FontFaceObserver.unload);
    return keysToRemove.length;
  }

  static bool unload(String key) {
    if (_loadedFonts.containsKey(key)) {
      var loadedFont = _loadedFonts[key];
      if (loadedFont.uses <= 1) {
        loadedFont.element.remove();
        _loadedFonts.remove(key);
      } else {
        loadedFont.uses--;
      }
      return true;
    }
    return false;
  }
}
