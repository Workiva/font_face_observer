import 'dart:html';
import 'dart:async';
import 'package:font_face_observer/font_face_observer.dart';
import 'package:font_face_observer/support.dart';

const String _successMessage = 'Pack my box with five dozen liquor jugs';
// const String _fontUrl = '/Shrikhand-b64.txt';
// const String _fontUrl = '/Shrikhand-Regular.ttf';
const String _fontUrl = '/Garamond.ttf';
const String _fontName = 'Garamond';
// const String _fontName = 'Arial';
const bool _USE_NATIVE_FONT_API = false;

drawText(String text, fontName) {
  CanvasElement canvas = document.getElementById('canvas');
  HtmlElement sentence = document.getElementById('sentence');
  CanvasRenderingContext2D ctx = canvas.getContext('2d');
  ctx.setFillColorRgb(255, 255, 255);
  ctx.fillRect(0,0, canvas.width, canvas.height);
  ctx.setFillColorRgb(0, 0, 0);
  ctx.font = '18px $fontName';
  ctx.fillText(text, 5, 20);
  sentence.text = text;
  sentence.style.fontFamily = fontName;
}

writeSupport() {
  var supportString = '''
supportsStretch: $SUPPORTS_STRETCH
supportsNativeFontLoading: $SUPPORTS_NATIVE_FONT_LOADING
hasWebKitFallbackBug: $HAS_WEBKIT_FALLBACK_BUG
  ''';
  document.getElementById('supports').text = supportString;
  print(supportString);
}

loadFont([ev]) async {
  print('Loading $_fontName... with native FontApi $_USE_NATIVE_FONT_API');
  drawText('Loading $_fontName ...', _fontName);
  // HttpRequest req = await HttpRequest.request(_fontUrl);
  // String fontData = req.response;

  // String fontObjectUrl = FontFaceObserver.getFontObjectUrlFrom(fontData);
  // print(fontObjectUrl);
  var ffo = new FontFaceObserver(_fontName, useSimulatedLoadEvents: !_USE_NATIVE_FONT_API);
  var loaded = await ffo.load(_fontUrl);
  // var loaded = await ffo.load(fontObjectUrl);

  // Url.revokeObjectUrl(fontObjectUrl);
  print('loaded: $loaded');
  drawText(loaded == true ? _successMessage : 'Font not loaded', _fontName);
}

main() {
  writeSupport();
  drawText('Waiting ...', _fontName);
  new Timer(new Duration(milliseconds: 1000), loadFont);
}
