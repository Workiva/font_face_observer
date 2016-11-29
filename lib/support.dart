import 'dart:html';

final bool HAS_WEBKIT_FALLBACK_BUG =
    _hasWebKitFallbackBug(window.navigator.userAgent);
final bool SUPPORTS_STRETCH = _supportsStretch();
final bool SUPPORTS_NATIVE_FONT_LOADING = _supportsNativeFontLoading();

/// Returns true if the browser supports font-style in the font short-hand syntax.
bool _supportsStretch() {
  var div = document.createElement('div');
  try {
    div.style.font = 'condensed 100px sans-serif';
  } catch (e) {}
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
  var regex = new RegExp('AppleWebKit\/([0-9]+)(?:\.([0-9]+))');
  var matches = regex.allMatches(userAgent);
  if (matches == null || matches.length == 0) {
    return false;
  }
  var match = matches.first;
  if (match == null) {
    return false;
  }
  var major = int.parse(match.group(1));
  var minor = int.parse(match.group(2));
  return major < 536 || (major == 536 && minor <= 11);
}
