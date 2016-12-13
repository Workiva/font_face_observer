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

const int DEFAULT_TIMEOUT = 3000;
const String DEFAULT_TEST_STRING = 'BESbswy';
const String _NORMAL = 'normal';
const int _NATIVE_FONT_LOADING_CHECK_INTERVAL = 50;
const String _FONT_FACE_CSS_ID = 'FONT_FACE_CSS';

/// Simple container object for result data
class FontLoadResult {
  final bool isLoaded;
  final bool didTimeout;
  FontLoadResult({this.isLoaded: true, this.didTimeout: false});

  @override
  String toString() =>
      'FontLoadResult {isLoaded: $isLoaded, didTimeout: $didTimeout}';
}

class FontFaceObserver {
  String family;
  String style;
  String weight;
  String stretch;
  String _testString;
  int timeout;
  bool useSimulatedLoadEvents;

  Completer _result = new Completer();
  StyleElement _styleElement;

  FontFaceObserver(String this.family,
      {String this.style: _NORMAL,
      String this.weight: _NORMAL,
      String this.stretch: _NORMAL,
      String testString: DEFAULT_TEST_STRING,
      int this.timeout: DEFAULT_TIMEOUT,
      bool this.useSimulatedLoadEvents: false}) {
    this.testString = testString;
    if (family != null) {
      family = family.trim();
      bool hasStartQuote = family.startsWith('"') || family.startsWith("'");
      bool hasEndQuote = family.endsWith('"') || family.endsWith("'");
      if (hasStartQuote && hasEndQuote) {
        family = family.substring(1, family.length - 1);
      }
    }
  }

  get testString => _testString;
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

  String _getStyle(String family) {
    var _stretch = SUPPORTS_STRETCH ? stretch : '';
    return '$style $weight $_stretch 100px $family';
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
    if (document.fonts.check(_getStyle('$family'), testString)) {
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
    // if the browser supports FontFace API set up an interval to check if
    // the font is loaded
    if (SUPPORTS_NATIVE_FONT_LOADING && !useSimulatedLoadEvents) {
      t = new Timer.periodic(
          new Duration(milliseconds: _NATIVE_FONT_LOADING_CHECK_INTERVAL),
          _periodicallyCheckDocumentFonts);
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
        if (widthSansSerif == widthSerif ||
            widthSansSerif == widthMonospace ||
            widthSerif == widthMonospace) {
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
            _result.complete(
                new FontLoadResult(isLoaded: true, didTimeout: false));
          }
        }
      }
    }

    // This ensures the scroll direction is correct.
    container.dir = 'ltr';

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

    _rulerSansSerif.setFont(_getStyle('"$family",sans-serif'));

    _rulerSerif.onResize((width) {
      widthSerif = width;
      _checkWidths();
    });

    _rulerSerif.setFont(_getStyle('"$family",serif'));

    _rulerMonospace.onResize((width) {
      widthMonospace = width;
      _checkWidths();
    });

    _rulerMonospace.setFont(_getStyle('"$family",monospace'));

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
      return _result.future;
    }
    // Add a single <style> tag to the DOM to insert font-face rules
    if (_styleElement == null) {
      _styleElement = document.getElementById(_FONT_FACE_CSS_ID);
      if (_styleElement == null) {
        _styleElement = new StyleElement()..id = _FONT_FACE_CSS_ID;
        _styleElement.text =
            '<!-- font_face_observer loads fonts using this element -->';
        document.head.append(_styleElement);
      }
    }

    var rule = '''
      @font-face {
        font-family: "${family}";
        font-style: ${style};
        font-weight: ${weight};
        src: url(${url});
      }''';

    CssStyleSheet sheet = _styleElement.sheet;

    sheet.insertRule(rule, 0);

    // Since browsers may not load a font until it is actually used
    // We add this span to trigger the browser to load the font when used
    SpanElement dummy = new SpanElement()
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
}
