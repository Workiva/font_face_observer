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
import 'package:font_face_observer/ruler.dart';

const int DEFAULT_TIMEOUT = 3000;
const String DEFAULT_TEST_STRING = 'BESbswy';
const String _NORMAL = 'normal';
const int _NATIVE_FONT_LOADING_POLL_INTERVAL = 50;
const String _FONT_FACE_CSS_ID = 'FONT_FACE_CSS';

class FontFaceObserver {
  final String family;
  final String style;
  final String weight;
  final String stretch;
  final String testString;
  final int timeout;
  final bool useSimulatedLoadEvents;

  Completer _loaded = new Completer();
  StyleElement _styleElement;

  FontFaceObserver(String this.family,
      {String this.style: _NORMAL,
      String this.weight: _NORMAL,
      String this.stretch: _NORMAL,
      String this.testString: DEFAULT_TEST_STRING,
      int this.timeout: DEFAULT_TIMEOUT,
      bool this.useSimulatedLoadEvents: false});

  String _getStyle(String family) {
    var _stretch = SUPPORTS_STRETCH ? stretch : '';
    return '$style $weight $_stretch 100px $family';
  }

  void _timeoutFunction(Timer t) {
    if (t != null && t.isActive) {
      t.cancel();
    }
    if (!_loaded.isCompleted) {
      _loaded.complete(false);
    }
  }

  _periodicFunction(Timer t) {
    if (document.fonts.check(_getStyle('$family'), testString)) {
      t.cancel();
      _loaded.complete(true);
    }
  }

  Future<bool> isLoaded() async {
    Timer t;
    if (_loaded.isCompleted) {
      return _loaded.future;
    }
    // if the browser supports FontFace API set up an interval to check if
    // the font is loaded
    if (SUPPORTS_NATIVE_FONT_LOADING && !useSimulatedLoadEvents) {
      t = new Timer.periodic(
          new Duration(milliseconds: _NATIVE_FONT_LOADING_POLL_INTERVAL),
          _periodicFunction);
    } else {
      t = _simulateFontLoadEvents();
    }

    // Start a timeout timer that will cancel everything and complete
    // our _loaded future with false if it isn't already completed
    new Timer(new Duration(milliseconds: timeout), () => _timeoutFunction(t));

    return _loaded.future;
  }

  Timer _simulateFontLoadEvents() {
    var _rulerA = new Ruler(testString);
    var _rulerB = new Ruler(testString);
    var _rulerC = new Ruler(testString);

    var widthA = -1;
    var widthB = -1;
    var widthC = -1;

    var fallbackWidthA = -1;
    var fallbackWidthB = -1;
    var fallbackWidthC = -1;

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
    check() {
      if ((widthA != -1 && widthB != -1) ||
          (widthA != -1 && widthC != -1) ||
          (widthB != -1 && widthC != -1)) {
        if (widthA == widthB || widthA == widthC || widthB == widthC) {
          // All values are the same, so the browser has most likely loaded the web font
          if (HAS_WEBKIT_FALLBACK_BUG) {
            // Except if the browser has the WebKit fallback bug, in which case we check to see if all
            // values are set to one of the last resort fonts.

            if (((widthA == fallbackWidthA &&
                    widthB == fallbackWidthA &&
                    widthC == fallbackWidthA) ||
                (widthA == fallbackWidthB &&
                    widthB == fallbackWidthB &&
                    widthC == fallbackWidthB) ||
                (widthA == fallbackWidthC &&
                    widthB == fallbackWidthC &&
                    widthC == fallbackWidthC))) {
              // The width we got matches some of the known last resort fonts, so let's assume we're dealing with the last resort font.
              return;
            }
          }
          if (container != null) {
            container.remove();
          }
          if (!_loaded.isCompleted) {
            _loaded.complete(true);
          }
        }
      }
    }

    // This ensures the scroll direction is correct.
    container.dir = 'ltr';

    _rulerA.setFont(_getStyle('sans-serif'));
    _rulerB.setFont(_getStyle('serif'));
    _rulerC.setFont(_getStyle('monospace'));

    container.append(_rulerA.element);
    container.append(_rulerB.element);
    container.append(_rulerC.element);

    document.body.append(container);

    fallbackWidthA = _rulerA.getWidth();
    fallbackWidthB = _rulerB.getWidth();
    fallbackWidthC = _rulerC.getWidth();

    _rulerA.onResize((width) {
      widthA = width;
      check();
    });

    _rulerA.setFont(_getStyle('"$family",sans-serif'));

    _rulerB.onResize((width) {
      widthB = width;
      check();
    });

    _rulerB.setFont(_getStyle('"$family",serif'));

    _rulerC.onResize((width) {
      widthC = width;
      check();
    });

    _rulerC.setFont(_getStyle('"$family",monospace'));

    return new Timer.periodic(new Duration(milliseconds: 50), (Timer t) {
      if (document.hidden) {
        widthA = _rulerA.getWidth();
        widthB = _rulerB.getWidth();
        widthC = _rulerC.getWidth();
        check();
      }
    });
  }

  /// Load the font into the browser given a url that could be a network url
  /// or a pre-built data or blob url.
  Future<bool> load(String url) async {
    if (_loaded.isCompleted) {
      return _loaded.future;
    }
    if (_styleElement == null) {
      _styleElement = document.getElementById(_FONT_FACE_CSS_ID);
      if (_styleElement == null) {
        _styleElement = new StyleElement()..id = _FONT_FACE_CSS_ID;
        _styleElement.text = '<!-- font_face_observer loads fonts using this element -->';
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

    // We need to create this span to force the font to be loaded into memory
    SpanElement dummy = new SpanElement()
      ..setAttribute('style', 'font-family: "${family}"; visibility: hidden;')
      ..text = testString;

    document.body.append(dummy); // TODO clean up dummy element from DOM
    var isLoadedFuture = isLoaded();
    _removeElementWhenComplete(isLoadedFuture, dummy);
    return isLoadedFuture;
  }

  _removeElementWhenComplete(Future f, HtmlElement el) async {
    f.whenComplete(() => el.remove());
  }
}
