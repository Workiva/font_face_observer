/*
Copyright 2017 Workiva Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

This software or document includes material copied from or derived 
from fontfaceobserver (https://github.com/bramstein/fontfaceobserver), 
Copyright (c) 2014 - Bram Stein, which is licensed under the following terms:

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions 
are met:
 
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer. 
 2. Redistributions in binary form must reproduce the above copyright 
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED 
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO 
EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This software or document includes material copied from or derived from 
CSS Font Loading Module Level 3 (https://drafts.csswg.org/css-font-loading/)
Copyright © 2017 W3C® (MIT, ERCIM, Keio, Beihang) which is licensed 
under the following terms:

By obtaining and/or copying this work, you (the licensee) agree that you 
have read, understood, and will comply with the following terms and conditions.
Permission to copy, modify, and distribute this work, with or without 
modification, for any purpose and without fee or royalty is hereby granted, 
provided that you include the following on ALL copies of the work or portions 
thereof, including modifications:
The full text of this NOTICE in a location viewable to users of the 
redistributed or derivative work. Any pre-existing intellectual property 
disclaimers, notices, or terms and conditions. If none exist, the W3C 
Software and Document Short Notice should be included.
Notice of any changes or modifications, through a copyright statement 
on the new code or document such as "This software or document 
includes material copied from or derived from 
[title and URI of the W3C document]. 
Copyright © [YEAR] W3C® (MIT, ERCIM, Keio, Beihang)."

https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
*/
import 'dart:async';
import 'dart:html';
import 'package:font_face_observer/support.dart';

/// The CSS class name to add to temporary DOM nodes when detecting font load.
const String fontFaceObserverTempClassname = '_ffo_temp';
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
  FontLoadResult({this.isLoaded = true, this.didTimeout = false});

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
  Map<String, int> groupUses = <String, int>{};
  Future<FontLoadResult> futureLoadResult;

  _FontRecord({required this.styleElement, required this.futureLoadResult});

  int get uses => _uses;
  set uses(int newUses) {
    _uses = newUses;
    styleElement.dataset['uses'] = _uses.toString();
  }

  int incrementGroupCount(String group) {
    if (_isWhitespace(group)) {
      return 0;
    }
    if (groupUses.containsKey(group)) {
      groupUses[group] = (groupUses[group] ?? 0) + 1;
    } else {
      groupUses[group] = 1;
    }
    _updateGroupUseCounts();
    return groupUses[group] ?? 0;
  }

  int decrementGroupCount(String group) {
    if (_isWhitespace(group)) {
      return 0;
    }
    if (groupUses.containsKey(group)) {
      groupUses[group] = (groupUses[group] ?? 0) - 1;
      if (groupUses[group]! <= 0) {
        groupUses.remove(group);
      }
    } else {
      groupUses.remove(group);
    }
    _updateGroupUseCounts();
    return groupUses[group] ?? 0;
  }

  bool isInGroup(String group) {
    if (_isWhitespace(group)) {
      return false;
    }
    if (groupUses.containsKey(group)) {
      return (groupUses[group] ?? 0) > 0;
    }
    return false;
  }

  /// Recalculcate the sum of total uses and total list of groups for this
  /// font record and update the data-groups attribute on the style element.
  /// It then "caches" the total number of uses in the [uses] property
  /// so we don't have to sum every time we want to check # of uses.
  void _updateGroupUseCounts() {
    if (groupUses.isNotEmpty) {
      uses = groupUses.values.reduce((int a, int b) => a + b);
    } else {
      uses = 0;
      groupUses.clear();
    }
    final StringBuffer groupData = StringBuffer();
    for (final group in groupUses.keys) {
      groupData.write('$group(${groupUses[group]}) ');
    }
    styleElement.dataset['groups'] = groupData.toString();
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

  /// This option is always false now that simulated font load event support is removed
  @Deprecated(
      'This option is always false now that simulated font load event support is removed')
  final bool useSimulatedLoadEvents = false;

  /// The internal group name
  String _group;

  /// The completer representing the load status of this font
  final Completer<FontLoadResult> _result = Completer<FontLoadResult>();

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

  FontFaceObserver(
      this.family,
      {this.style = _normal,
      this.weight = _normal,
      this.stretch = _normal,
      String testString = _defaultTestString,
      this.timeout = _defaultTimeout,
      @Deprecated('This option does nothing now that simulated font load event support is removed')
          useSimulatedLoadEvents = false,
      String group = defaultGroup})
      : _testString =
            _isWhitespace(testString) ? _defaultTestString : testString,
        _group = _isWhitespace(group) ? defaultGroup : group {
    _group = _isWhitespace(group) ? defaultGroup : group;
    family = family.trim();
    final bool hasStartQuote = family.startsWith('"') || family.startsWith("'");
    final bool hasEndQuote = family.endsWith('"') || family.endsWith("'");
    if (hasStartQuote && hasEndQuote) {
      family = family.substring(1, family.length - 1);
    }
  }

  /// A global map of unique font key String to _LoadedFont
  static final Map<String, _FontRecord> _loadedFonts = <String, _FontRecord>{};

  /// The default group used for a font if none is specified.
  static const String defaultGroup = 'default';

  /// Returns the font keys for all currently loaded fonts
  static Iterable<String> getLoadedFontKeys() => _loadedFonts.keys.toSet();

  /// Returns the groups that the currently loaded fonts are in.
  /// There will not be duplicate group entries if there are multiple fonts
  /// in the same group.
  static Iterable<String> getLoadedGroups() {
    final Set<String> loadedGroups = Set<String>();

    void getLoadedGroups(String k) {
      final _FontRecord record = _loadedFonts[k]!;
      loadedGroups.addAll(record.groupUses.keys);
    }

    _loadedFonts.keys.forEach(getLoadedGroups);
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
    if (_isWhitespace(group)) {
      return 0;
    }

    // parallel arrays of keys and groups that go along with the keys at the
    // same indexes.
    final List<String> keysToRemove = <String>[];
    final List<_FontRecord> records = <_FontRecord>[];
    for (String k in _loadedFonts.keys.toList()) {
      final _FontRecord record = _loadedFonts[k]!;
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
      final _FontRecord record = _loadedFonts[key]!;
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
        _isWhitespace(newTestString) ? _defaultTestString : newTestString;
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

    final record = _loadedFonts[key];
    if (record == null) {
      return FontLoadResult(isLoaded: false, didTimeout: false);
    }

    // Since browsers may not load a font until it is actually used (lazily loaded)
    // We add this span to trigger the browser to load the font when used
    final String _key = '_ffo_dummy_${key}';
    var dummy = document.getElementById(_key);
    if (dummy == null) {
      dummy = SpanElement()
        ..className = '$fontFaceObserverTempClassname _ffo_dummy'
        ..id = _key
        ..setAttribute('style', 'font-family: "${family}"; visibility: hidden;')
        ..text = testString;
      document.body!.append(dummy);
    }

    // Assume the browser supports FontFace API
    // set up an interval to check if the font is loaded
    t = Timer.periodic(
        const Duration(milliseconds: _nativeFontLoadingCheckInterval),
        _periodicallyCheckDocumentFonts);

    // Start a timeout timer that will cancel everything and complete
    // our _loaded future with false if it isn't already completed
    Timer(Duration(milliseconds: timeout), () => _onTimeout(t));

    return _result.future.then((FontLoadResult flr) {
      if (t.isActive) {
        t.cancel();
      }
      dummy?.remove();
      return flr;
    });
  }

  /// Load the font into the browser given a url that could be a network url
  /// or a pre-built data or blob url.
  Future<FontLoadResult> load(String url) async {
    final record = _load(url);
    if (_result.isCompleted) {
      return _result.future;
    }

    try {
      final FontLoadResult flr = await check();
      if (flr.isLoaded) {
        return _result.future;
      }
    } on Exception {
      // On errors, make sure the font is unloaded
      _unloadFont(key, record);
      return FontLoadResult(isLoaded: false, didTimeout: false);
    }

    // if we get here, the font load has timed out
    // make sure the font is unloaded
    _unloadFont(key, record);
    return FontLoadResult(isLoaded: false, didTimeout: true);
  }

  /// Loads the font by either returning the existing _FontRecord if a font is
  /// already loaded (and incrementing its use count)
  /// or by adding a new style element to the DOM to load the font with an
  /// initial use count of 1.
  _FontRecord _load(String url) {
    StyleElement styleElement;
    final String _key = key;
    late _FontRecord record;
    if (_loadedFonts.containsKey(_key) && _loadedFonts[_key] != null) {
      record = _loadedFonts[_key]!;
    } else {
      final String rule = '''
      @font-face {
        font-family: "${family}";
        font-style: ${style};
        font-weight: ${weight};
        src: url(${url});
      }''';

      styleElement = StyleElement()
        ..className = '_ffo'
        ..text = rule
        ..dataset['key'] = _key;

      record = _FontRecord(
          styleElement: styleElement, futureLoadResult: _result.future);

      _loadedFonts[_key] = record;
      document.head!.append(styleElement);
    }
    record.incrementGroupCount(group);
    return record;
  }

  /// Generates the CSS style string to be used when detecting a font load
  /// for a given [family] at a certain [cssSize] (default 100px)
  String _getStyle(String family, {String cssSize = '100px'}) {
    final String _stretch = supportsStretch ? stretch : '';
    return '$style $weight $_stretch $cssSize $family';
  }

  /// This gets called when the timeout has been reached.
  /// It will cancel the passed in Timer if it is still active and
  /// complete the result with a timed out FontLoadResult
  void _onTimeout(Timer t) {
    if (t.isActive) {
      t.cancel();
    }
    if (!_result.isCompleted) {
      _result.complete(FontLoadResult(isLoaded: false, didTimeout: true));
    }
  }

  /// Checks if a font is loaded in the browser using the browser
  /// built in Font Face API. If it is loaded, the passed in Timer [t] will
  /// be cancelled. If the font is not loaded, this is a no-op.
  void _periodicallyCheckDocumentFonts(Timer t) {
    if (document.fonts!.check(_getStyle('"$family"'), testString)) {
      t.cancel();
      _result.complete(FontLoadResult(isLoaded: true, didTimeout: false));
    }
  }

  // Internal method to forcibly remove the font. It removes all DOM references
  // and removes the font from internal tracking.
  static void _unloadFont(String key, _FontRecord record) {
    record.styleElement.remove();
    _loadedFonts.remove(key);
  }
}

bool _isWhitespace(String s) => s.trim().isEmpty;
