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
*/
import 'dart:html';

/// Is true if this browser is WebKit and it has the fallback bug
/// which is present in WebKit 536.11 and earlier.
final bool hasWebkitFallbackBug =
    _hasWebKitFallbackBug(window.navigator.userAgent);

/// Is true if the current browser supports the CSS font face stretch property
final bool supportsStretch = _supportsStretch();

/// Is true if the current browser supports the Font Face API
final bool supportsNativeFontLoading = _supportsNativeFontLoading();

/// Returns true if the browser supports font-style in the font short-hand syntax.
bool _supportsStretch() {
  Element div = document.createElement('div');
  try {
    // Detect if the browser supports the CSS font-stretch property by trying
    // to set it on a new empty div. Using condensed will cause an exception
    // in browsers that don't support it.
    div.style.font = 'condensed 100px sans-serif';
  } catch (_) {}
  // If the font style still has a value, that means the browser accepts
  // stretch as a valid value and supports it
  return div.style.font != '';
}

bool _supportsNativeFontLoading() {
  bool supports = true;
  try {
    document.fonts.status;
  } catch (x) {
    supports = false;
  }
  return supports;
}

/// Returns true if this browser is WebKit and it has the fallback bug
/// which is present in WebKit 536.11 and earlier.
bool _hasWebKitFallbackBug(String userAgent) {
  RegExp regex = new RegExp('AppleWebKit\/([0-9]+)(?:\.([0-9]+))');
  Iterable<Match> matches = regex.allMatches(userAgent);
  if (matches == null || matches.length == 0) {
    return false;
  }
  Match match = matches.first;
  if (match == null) {
    return false;
  }
  num major = int.parse(match.group(1));
  num minor = int.parse(match.group(2));
  return major < 536 || (major == 536 && minor <= 11);
}
