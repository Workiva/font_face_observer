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

const int _defaultTimeout = 3000;
const String _defaultTestString = 'BESbswy';
const String _normal = 'normal';
const int _nativeFontLoadingCheckInterval = 50;

/// A simple immutable container object for font load result data.
class FontLoadResult {
  /// true if the font is loaded successfully, false otherwise
  final bool isLoaded;

  /// true if timed out while waiting for the font to be loaded
  final bool didTimeout;

  // ignoring since the constructor is so simple, docs are just redundant
  // ignore: public_member_api_docs
  FontLoadResult({this.isLoaded: true, this.didTimeout: false});

  @override
  String toString() =>
      'FontLoadResult {isLoaded: $isLoaded, didTimeout: $didTimeout}';
}

/// A [_FontRecord] holds data about each loaded font.
/// Each distinct font will have only 1 entry in the _loadedFonts map
/// of the font key -> _FontRecord
class _FontRecord {
  int _uses = 0;
  StyleElement styleElement;
  Map<String, int> groupUses = new Map<String, int>();
  Future<FontLoadResult> futureLoadResult;

  int get uses => _uses;
  set uses(int newUses) {
    _uses = newUses;
    styleElement.dataset['uses'] = _uses.toString();
  }

  int incrementGroupCount(String group) {
    if (_isNullOrWhitespace(group)) {
      return groupUses[group];
    }
    if (groupUses.containsKey(group)) {
      groupUses[group]++;
    } else {
      groupUses[group] = 1;
    }
    _updateGroupUseCounts();
    return groupUses[group];
  }

  int decrementGroupCount(String group) {
    if (_isNullOrWhitespace(group)) {
      return groupUses[group];
    }
    if (groupUses.containsKey(group)) {
      groupUses[group]--;
      if (groupUses[group] <= 0) {
        groupUses.remove(group);
      }
    } else {
      groupUses.remove(group);
    }
    _updateGroupUseCounts();
    return groupUses[group];
  }

  bool isInGroup(String group) {
    if (_isNullOrWhitespace(group)) {
      return false;
    }
    if (groupUses.containsKey(group)) {
      return groupUses[group] > 0;
    }
    return false;
  }

  /// Recalculcate the sum of total uses and total list of groups for this
  /// font record and update the data-groups attribute on the style element.
  /// It then "caches" the total number of uses in the [uses] property
  /// so we don't have to sum every time we want to check # of uses.
  void _updateGroupUseCounts() {
    if (groupUses.length > 0) {
      uses = groupUses.values.reduce((int a, int b) => a + b);
    } else {
      uses = 0;
      groupUses.clear();
    }
    String groupData = '';
    for (String group in groupUses.keys) {
      groupData += '$group(${groupUses[group]}) ';
    }
    styleElement.dataset['groups'] = groupData;
  }
}

/// A FontFaceObserver is responsible for loading and detecting when a font
/// has been successfully loaded into the browser and is ready for use in the
/// DOM or drawn into a canvas. If you need to load fonts with an authenticated
/// request, you can handle the networking part yourself and then still use
/// FontFaceObserver to detect when it is ready by passing in the font as a
/// base64 data or Blob URI.
class FontFaceObserver {
  /// CSS font family
  String family;

  /// CSS font style
  String style;

  /// CSS font weight
  String weight;

  /// CSS font stretch
  String stretch;

  /// The internal test string to use when detecting font loads
  String _testString;

  /// How long to wait in ms when detecting font loads before timing out
  int timeout;

  /// true forces simulated font load events, false will auto-detect the
  /// capability of the browser and only use simulated if the Font Face API
  /// is not supported
  bool useSimulatedLoadEvents;

  /// The internal group name
  String _group;

  /// The completer representing the load status of this font
  Completer<FontLoadResult> _result = new Completer<FontLoadResult>();

  Ruler _rulerSansSerif;
  Ruler _rulerSerif;
  Ruler _rulerMonospace;

  /// Construct a new FontFaceObserver. The CSS font family name is the only
  /// required parameter.
  ///
  /// Defaults:
  /// ```
  /// String style: 'normal'
  /// String weight: 'normal'
  /// String stretch: 'normal'
  /// String testString: 'BESbswy'
  /// int timeout: 3000
  /// bool useSimulatedLoadEvents: false
  /// ```

  FontFaceObserver(this.family,
      {this.style: _normal,
      this.weight: _normal,
      this.stretch: _normal,
      String testString: _defaultTestString,
      this.timeout: _defaultTimeout,
      this.useSimulatedLoadEvents: false,
      String group: defaultGroup}) {
    if (key != adobeBlankKey && !_loadedFonts.containsKey(adobeBlankKey)) {
      _adobeBlankLoadedFuture = _loadAdobeBlank();
    }
    this.testString = testString;
    this._group = _isNullOrWhitespace(group) ? defaultGroup : group;
    if (family != null) {
      family = family.trim();
      bool hasStartQuote = family.startsWith('"') || family.startsWith("'");
      bool hasEndQuote = family.endsWith('"') || family.endsWith("'");
      if (hasStartQuote && hasEndQuote) {
        family = family.substring(1, family.length - 1);
      }
    }
  }

  /// A global map of unique font key String to _LoadedFont
  static Map<String, _FontRecord> _loadedFonts = new Map<String, _FontRecord>();

  /// The default group used for a font if none is specified.
  static const String defaultGroup = 'default';
  static Future<FontLoadResult> _adobeBlankLoadedFuture = _loadAdobeBlank();
  static Future<FontLoadResult> _loadAdobeBlank() {
    return (new FontFaceObserver(adobeBlankFamily, group: adobeBlankFamily))
        .load(adobeBlankFontBase64Url);
  }

  /// Returns the font keys for all currently loaded fonts
  static Iterable<String> getLoadedFontKeys() {
    return _loadedFonts.keys.toSet();
  }

  /// Returns the groups that the currently loaded fonts are in.
  /// There will not be duplicate group entries if there are multiple fonts
  /// in the same group.
  static Iterable<String> getLoadedGroups() {
    Set<String> loadedGroups = new Set<String>();
    _loadedFonts.keys.forEach((String k) {
      _FontRecord record = _loadedFonts[k];
      loadedGroups.addAll(record.groupUses.keys);
    });
    return loadedGroups;
  }

  /// Sets the use count for the given [group] to zero for any fonts in that
  /// group, then unloads any fonts that are not used any more.
  /// A font will only be actually unloaded from the browser once its use count
  /// is zero. So, if the same font is used by multiple different groups
  /// it will have a count of uses per group and will need to be unloaded from
  /// each group to truly unload it from the browser.
  ///
  /// Returns the number of fonts that have been affected.
  /// A [group] of null or only whitespace is invalid and will return zero
  static Future<int> unloadGroup(String group) async {
    // do nothing if no group is passed in
    if (_isNullOrWhitespace(group)) {
      return 0;
    }

    // parallel arrays of keys and groups that go along with the keys at the
    // same indexes.
    List<String> keysToRemove = new List<String>();
    List<_FontRecord> records = new List<_FontRecord>();
    for (String k in _loadedFonts.keys.toList()) {
      _FontRecord record = _loadedFonts[k];
      // wait for the load future to complete
      await record.futureLoadResult;

      if (record.isInGroup(group)) {
        record.groupUses.remove(group);
        record._updateGroupUseCounts();
        if (record.uses <= 0) {
          keysToRemove.add(k);
          records.add(record);
        }
      }
    }
    for (int k = 0; k < keysToRemove.length; k++) {
      _unloadFont(keysToRemove[k], records[k]);
    }

    return keysToRemove.length;
  }

  /// Unloads a font by passing in the [key] and [group] that was used to load
  /// it originally. It will decremement the use count for a matching font
  /// and if no one else is using it, then it will be removed from the browser
  /// by removing the style element and removing the internal tracking of the
  /// font.
  ///
  /// Returns true if the font was found and decremented, false if the
  /// key/group combo was not found.
  static Future<bool> unload(String key, String group) async {
    if (_loadedFonts.containsKey(key)) {
      _FontRecord record = _loadedFonts[key];
      // wait for the load future to complete
      await record.futureLoadResult;

      record.decrementGroupCount(group);

      if (record.uses <= 0) {
        _unloadFont(key, record);
      }

      return true;
    }
    return false;
  }

  /// Returns the key for this FontFaceObserver
  String get key => '${family}_${style}_${weight}_${stretch}';

  /// Returns the group that this FontFaceObserver is in
  String get group => _group;

  /// Returns the test string used to detect this font load
  String get testString => _testString;

  /// Sets the test string to be used when detecting this font load
  /// If [newTestString] is null or only whitespace, the default test string
  /// will be used.
  set testString(String newTestString) {
    _testString =
        _isNullOrWhitespace(newTestString) ? _defaultTestString : newTestString;
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

    _FontRecord record = _loadedFonts[key];
    if (record == null) {
      return new FontLoadResult(isLoaded: false, didTimeout: false);
    }

    if (family != adobeBlankFamily) {
      await _adobeBlankLoadedFuture;
    }

    // Since browsers may not load a font until it is actually used (lazily loaded)
    // We add this span to trigger the browser to load the font when used
    String _key = '_ffo_dummy_${key}';
    SpanElement dummy = document.getElementById(_key);
    if (dummy == null) {
      dummy = new SpanElement()
        ..className = '$fontFaceObserverTempClassname _ffo_dummy'
        ..id = _key
        ..setAttribute('style', 'font-family: "${family}"; visibility: hidden;')
        ..text = testString;
      document.body.append(dummy);
    }

    // if the browser supports FontFace API set up an interval to check if
    // the font is loaded
    if (supportsNativeFontLoading && !useSimulatedLoadEvents) {
      t = new Timer.periodic(
          new Duration(milliseconds: _nativeFontLoadingCheckInterval),
          _periodicallyCheckDocumentFonts);
    } else {
      t = _simulateFontLoadEvents();
    }

    // Start a timeout timer that will cancel everything and complete
    // our _loaded future with false if it isn't already completed
    new Timer(new Duration(milliseconds: timeout), () => _onTimeout(t));

    return _result.future.then((FontLoadResult flr) {
      dummy.remove();
      _dispose();
      return flr;
    });
  }

  /// Load the font into the browser given a url that could be a network url
  /// or a pre-built data or blob url.
  Future<FontLoadResult> load(String url) async {
    _FontRecord record = _load(url);
    if (_result.isCompleted) {
      return _result.future;
    }

    try {
      FontLoadResult flr = await check();
      if (flr.isLoaded) {
        return _result.future;
      }
    } catch (x) {
      // On errors, make sure the font is unloaded
      _unloadFont(key, record);
      return new FontLoadResult(isLoaded: false, didTimeout: false);
    }

    // if we get here, the font load has timed out
    // make sure the font is unloaded
    _unloadFont(key, record);
    return new FontLoadResult(isLoaded: false, didTimeout: true);
  }

  /// Loads the font by either returning the existing _FontRecord if a font is
  /// already loaded (and incrementing its use count)
  /// or by adding a new style element to the DOM to load the font with an
  /// initial use count of 1.
  _FontRecord _load(String url) {
    StyleElement styleElement;
    String _key = key;
    _FontRecord record;
    if (_loadedFonts.containsKey(_key)) {
      record = _loadedFonts[_key];
    } else {
      String rule = '''
      @font-face {
        font-family: "${family}";
        font-style: ${style};
        font-weight: ${weight};
        src: url(${url});
      }''';

      styleElement = new StyleElement()
        ..className = '_ffo'
        ..text = rule
        ..dataset['key'] = _key;

      record = new _FontRecord()
        ..styleElement = styleElement
        ..futureLoadResult = _result.future;

      _loadedFonts[_key] = record;
      document.head.append(styleElement);
    }
    record.incrementGroupCount(group);
    return record;
  }

  /// Generates the CSS style string to be used when detecting a font load
  /// for a given [family] at a certain [cssSize] (default 100px)
  String _getStyle(String family, {String cssSize: '100px'}) {
    String _stretch = supportsStretch ? stretch : '';
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

  /// Checks is a font is loaded in the browser using the browser
  /// built in Font Face API. If it is loaded, the passed in Timer [t] will
  /// be cancelled. If the font is not loaded, this is a no-op.
  void _periodicallyCheckDocumentFonts(Timer t) {
    if (document.fonts.check(_getStyle('"$family"'), testString)) {
      t.cancel();
      _result.complete(new FontLoadResult(isLoaded: true, didTimeout: false));
    }
  }

  /// Simulate Font Face API load events to detect when a font is loaded and
  /// ready in the browser. It does this with a series of "rulers" that at least
  /// one of which will trigger a scroll event when the font loads and the
  /// dimensions of the test string change. These rulers are checked periodically
  /// waiting for the font to become available. The Timer is returned so it may
  /// be cancelled and not check infinitely.
  Timer _simulateFontLoadEvents() {
    _rulerSansSerif = new Ruler(testString);
    _rulerSerif = new Ruler(testString);
    _rulerMonospace = new Ruler(testString);

    num widthSansSerif = -1;
    num widthSerif = -1;
    num widthMonospace = -1;

    num fallbackWidthSansSerif = -1;
    num fallbackWidthSerif = -1;
    num fallbackWidthMonospace = -1;

    Element container = document.createElement('div');

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
    void _checkWidths() {
      if ((widthSansSerif != -1 && widthSerif != -1) ||
          (widthSansSerif != -1 && widthMonospace != -1) ||
          (widthSerif != -1 && widthMonospace != -1)) {
        if (widthSansSerif == widthSerif ||
            widthSansSerif == widthMonospace ||
            widthSerif == widthMonospace) {
          // All values are the same, so the browser has most likely loaded the web font
          if (hasWebkitFallbackBug) {
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
    // add class names for tracking nodes if they leak (and for testing)
    container.className = '$fontFaceObserverTempClassname _ffo_container';
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

    _rulerSansSerif.onResize((num width) {
      widthSansSerif = width;
      _checkWidths();
    });

    _rulerSansSerif.setFont(_getStyle('"$family",AdobeBlank,sans-serif'));

    _rulerSerif.onResize((num width) {
      widthSerif = width;
      _checkWidths();
    });

    _rulerSerif.setFont(_getStyle('"$family",AdobeBlank,serif'));

    _rulerMonospace.onResize((num width) {
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

  // Internal method to forcibly remove the font. It removes all DOM references
  // and removes the font from internal tracking.
  static void _unloadFont(String key, _FontRecord record) {
    record.styleElement.remove();
    _loadedFonts.remove(key);
  }

  void _dispose() {
    _rulerSansSerif?.dispose();
    _rulerSerif?.dispose();
    _rulerMonospace?.dispose();
  }
}

bool _isNullOrWhitespace(String s) {
  return s == null || s.trim().isEmpty;
}
