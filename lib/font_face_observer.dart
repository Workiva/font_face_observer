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

/// Simple container object for result data
class FontLoadResult {
  final bool isLoaded;
  final bool didTimeout;
  FontLoadResult({this.isLoaded: true, this.didTimeout: false});

  @override
  String toString() =>
      'FontLoadResult {isLoaded: $isLoaded, didTimeout: $didTimeout}';
}

/// holds data about each loaded font
/// each font will have 1 _FontRecord in a map with the key pointing to it
class _FontRecord {
  StyleElement styleElement;
  Map<String, int> groupUses = new Map<String, int>();
  int _uses = 0;
  
  Future<FontLoadResult> futureLoadResult;

  int get uses => _uses;
  void set uses(int new_uses) {
    _uses = new_uses;
    styleElement.dataset['uses'] = _uses.toString();
  }

  void _recalc() {
    if (groupUses.length > 0) {
      uses = groupUses.values.reduce((a,b) => a + b);
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

  int incrementGroupCount(String group) {
    if (group == null || group.trim().isEmpty) {
      return groupUses[group];  
    }
    if (groupUses.containsKey(group)) {
      groupUses[group]++;
    } else {
      groupUses[group] = 1;
    }
    _recalc();
    return groupUses[group];
  }

  int decrememntGroupCount(String group) {
    if (group == null || group.trim().isEmpty) {
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
    _recalc();
    return groupUses[group];
  }

  bool isInGroup(String group) {
    if (group == null || group.trim().isEmpty) {
      return false;
    }
    if (groupUses.containsKey(group)) {
      return groupUses[group] > 0;
    }
    return false;
  }

  @override
  String toString() {
    return '_uses: $_uses groupUses: $groupUses';
  }
}

class FontFaceObserver {
  static const String defaultGroup = "default";
  static Future<FontLoadResult> _adobeBlankLoadedFuture = loadAdobeBlank();
  static Future<FontLoadResult> loadAdobeBlank() {
    return (new FontFaceObserver(AdobeBlankFamily, group: AdobeBlankFamily))
        .load(AdobeBlankFontBase64Url);
  }
  String family;
  String style;
  String weight;
  String stretch;
  String _testString;
  int timeout;
  bool useSimulatedLoadEvents;
  String _group;
  Completer<FontLoadResult> _result = new Completer<FontLoadResult>();

  /// A map of font key String to _LoadedFont
  static Map<String, _FontRecord> _loadedFonts = new Map<String, _FontRecord>();

  FontFaceObserver(String this.family,
      {String this.style: _NORMAL,
      String this.weight: _NORMAL,
      String this.stretch: _NORMAL,
      String testString: DEFAULT_TEST_STRING,
      int this.timeout: DEFAULT_TIMEOUT,
      bool this.useSimulatedLoadEvents: false,
      String group: defaultGroup}) {
    
    if (key != AdobeBlankKey && !_loadedFonts.containsKey(AdobeBlankKey)) {
      _adobeBlankLoadedFuture = loadAdobeBlank();
    }
    this.testString = testString;
    this.group = group;
    if (family != null) {
      family = family.trim();
      bool hasStartQuote = family.startsWith('"') || family.startsWith("'");
      bool hasEndQuote = family.endsWith('"') || family.endsWith("'");
      if (hasStartQuote && hasEndQuote) {
        family = family.substring(1, family.length - 1);
      }
    }
  }

  String get key => '${family}_${style}_${weight}_${stretch}';

  String get group => _group;
  void set group(String group) {
    if (group == null || group == '' || group.trim() == '') {
      throw new Exception(
          'FontFaceObserver group cannot be null or whitespace only');
    }
    
    if (this._group == group) {
      return;
    }

    // update a loaded font to the new group if there is one
    var _key = key;
    if (_loadedFonts.containsKey(_key)) {
      _loadedFonts[_key].incrementGroupCount(group);
      _loadedFonts[_key].decrememntGroupCount(this._group);
    }

    this._group = group;
  }

  String get testString => _testString;

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

  _FontRecord _load(String url) {
    StyleElement styleElement;
    String _key = key;
    _FontRecord record;
    if (_loadedFonts.containsKey(_key)) {
      record = _loadedFonts[_key];
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
        ..dataset['key'] = _key;

      record = new _FontRecord()
        ..styleElement = styleElement
        ..futureLoadResult = _result.future;
      record.incrementGroupCount(group);
      _loadedFonts[_key] = record;
      document.head.append(styleElement);
    }
    return record;
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

    return _result.future.then((FontLoadResult flr) {
      dummy.remove();
      return flr;
    });
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
      // fall through intentionally
    }

    // if we get here, the font load has timed out or errored out
    // we clean up by removing the font record and DOM nodes
    _unloadFont(key, record);
    // TODO return a failed future
    return _result.future;
  }

  /// A synchronous option for checking if the font that this FontFaceObserver
  /// instance represents is loaded
  bool get isLoaded {
    var loadedFont = _loadedFonts[key];
    return loadedFont != null && loadedFont.uses > 0;
  }

  /// A list of font keys for all currently loaded fonts
  static Iterable<String> getLoadedFontKeys() {
    return _loadedFonts.keys.toSet();
  }

  /// A list of groups that the currently loaded fonts are in
  /// There will not be duplicate group entries if there are multiple fonts
  /// in the same group.
  static Iterable<String> getLoadedGroups() {
    Set<String> loadedGroups = new Set<String>();
    _loadedFonts.keys.forEach((k) {
      var record = _loadedFonts[k];
      loadedGroups.addAll(record.groupUses.keys);
    });
    return loadedGroups;
  }

  /// Removes all fonts that are in the given [group]
  static Future<int> unloadGroup(String group) async {
    // do nothing if no group is passed in
    if (group == null || group == "") {
      return 0;
    }

    // parallel arrays of keys and groups that go along with the keys at the
    // same indexes.
    var keysToRemove = [];
    var records = [];
    for (String k in _loadedFonts.keys.toList()) {
    // _loadedFonts.keys.forEach(await (k) async {
      var record = _loadedFonts[k];
      // wait for the load future to complete
      await record.futureLoadResult;

      if (record.isInGroup(group)) {
        record.groupUses.remove(group);
        record._recalc();
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

  /// Unloads a font by unique key from the browser by removing the style
  /// element and removing the internal tracking of the font
  static Future<bool> unload(String key, String group) async {
    if (_loadedFonts.containsKey(key)) {
      var record = _loadedFonts[key];
      // wait for the load future to complete
      await record.futureLoadResult;
      
      record.decrememntGroupCount(group);

      if (record.uses <= 0) {
        _unloadFont(key, record);
      }
      
      return true;
    }
    return false;
  }


  // internal method to forcibly remove the font. It removes all DOM references
  // and removes the font from internal tracking.
  static void _unloadFont(String key, _FontRecord record) {
    record.styleElement.remove();
    _loadedFonts.remove(key);
  }
}