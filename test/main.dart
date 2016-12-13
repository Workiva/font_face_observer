import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'dart:js';
import 'dart:typed_data';
import 'package:font_face_observer/font_face_observer.dart';
import 'package:font_face_observer/support.dart';

const String _successMessage = 'Pack my box with five dozen liquor jugs';
const String _fontUrl = '/fonts/Garamond.ttf';
const String _fontName = 'Garamond';
const bool _USE_NATIVE_FONT_API = true;

drawText(String text, fontName, {canvasId: 'canvas', updateSentence: true}) {
  CanvasElement canvas = document.getElementById(canvasId);
  
  CanvasRenderingContext2D ctx = canvas.getContext('2d');
  ctx.setFillColorRgb(255, 255, 255);
  ctx.fillRect(0,0, canvas.width, canvas.height);
  ctx.setFillColorRgb(0, 0, 0);
  ctx.font = '18px $fontName';
  ctx.fillText(text, 5, 20);
  if (updateSentence) {
    HtmlElement sentence = document.getElementById('sentence');
    sentence.text = text;
    sentence.style.fontFamily = fontName;
    sentence = document.getElementById('svgsentence');
    sentence.text = text;
    sentence.style.fontFamily = fontName;
  }
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

loadFont(String fontFamily, String url, String message) async {
  print('Loading $fontFamily... with native FontApi $_USE_NATIVE_FONT_API');
  drawText('Loading $fontFamily ...', fontFamily);
  var ffo = new FontFaceObserver(fontFamily, useSimulatedLoadEvents: !_USE_NATIVE_FONT_API);
  var result = await ffo.load(url);
  print('loaded: $result');
  if (result.isLoaded) {
    drawText(message, fontFamily);
  } else {
    drawText(result.toString(), 'serif');
  }
}

main() async {
  writeSupport();
  drawText('Waiting ...', _fontName);

  document.getElementById('b64').onClick.listen( (ev) async {
    HttpRequest req = await HttpRequest.request(_fontUrl, responseType: 'arraybuffer');
    ByteBuffer fontData = req.response;
    String base64fontData = BASE64.encode(fontData.asUint8List().toList());
    base64fontData = 'data:application/octet-stream;base64,${base64fontData}';
    var result = await new FontFaceObserver('base64font').load(base64fontData);
    print('Loaded b64 $result');
    drawText(result.isLoaded ? _successMessage : 'Font not loaded', 'base64font');
  });
  
  document.getElementById('blob').onClick.listen( (ev) async {
    HttpRequest req = await HttpRequest.request(_fontUrl, responseType: 'blob');
    Blob blob = req.response;
    String blobUrl = Url.createObjectUrl(blob);
    var result = await new FontFaceObserver('blobfont').load(blobUrl);
    Url.revokeObjectUrl(blobUrl);
    print('Loaded blob font $result');
    drawText(result.isLoaded ? _successMessage : 'Font not loaded', 'blobfont');
  });

  document.getElementById('btn').onClick.listen( (ev) {
    loadFont('Garamond', 'fonts/Garamond.ttf', _successMessage);
  });
  
  document.getElementById('wbtn').onClick.listen( (ev) {
    loadFont('W', 'fonts/W.ttf', 'show me a Workiva W here:  \uE0FF');
  });
}
