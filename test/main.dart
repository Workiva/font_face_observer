import 'dart:html';
import 'package:font_face_observer/font_face_observer.dart';
import 'package:font_face_observer/support.dart';
import 'package:font_face_observer/src/adobe_blank.dart';

const String _successMessage = 'Pack my box with five dozen liquor jugs';

class FontConfig {
  String url;
  String family;
  String testString;
  bool useSimulatedLoadEvents;
  bool expectLoad;
  FontConfig({this.family, this.url, this.testString: _successMessage, this.expectLoad: true, this.useSimulatedLoadEvents: false });
}

final List<FontConfig> fonts = [
  new FontConfig(family: 'AdobeBlank', url: AdobeBlankFontBase64Url),
  new FontConfig(family: 'AdobeBlank', url: AdobeBlankFontBase64Url, useSimulatedLoadEvents: true),

  new FontConfig(family: 'Roboto', url: '/fonts/Roboto.ttf'),
  new FontConfig(family: 'Roboto', url: '/fonts/Roboto.ttf', useSimulatedLoadEvents: true),

  new FontConfig(family: 'Wdesk_Icons', url: '/fonts/Wdesk_Icons.ttf',testString: '\uE600 \uE601'),
  new FontConfig(family: 'Wdesk_Icons', url: '/fonts/Wdesk_Icons.ttf',testString: '\uE600 \uE601', useSimulatedLoadEvents: true),

  new FontConfig(family: 'Wdesk_Doctype-Icons', url: '/fonts/Wdesk_Doctype-Icons.ttf', testString: '\uE6D9 \uE026'),
  new FontConfig(family: 'Wdesk_Doctype-Icons', url: '/fonts/Wdesk_Doctype-Icons.ttf', testString: '\uE6D9 \uE026', useSimulatedLoadEvents: true),

  new FontConfig(family: 'Subset', url: '/fonts/subset.ttf', testString: '\u25FC \u4E2D \u56FD'),
  new FontConfig(family: 'Subset', url: '/fonts/subset.ttf', testString: '\u25FC \u4E2D \u56FD', useSimulatedLoadEvents: true),

  new FontConfig(family: 'empty', url: '/fonts/empty.otf', expectLoad: true, testString: '', useSimulatedLoadEvents: true),

  new FontConfig(family: 'W', url: '/fonts/W.ttf', testString: '\uE0FF'),
  new FontConfig(family: 'W', url: '/fonts/W.ttf', testString: '\uE0FF', useSimulatedLoadEvents: true)

];

drawTextToCanvas(String text, String fontName, CanvasElement canvas) {  
  CanvasRenderingContext2D ctx = canvas.getContext('2d');
  ctx.setFillColorRgb(255, 255, 255);
  ctx.fillRect(0,0, canvas.width, canvas.height);
  ctx.setFillColorRgb(0, 0, 0);
  ctx.font = '18px $fontName';
  ctx.fillText(text, 5, 28);
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

loadFont(FontConfig cfg, bool useSimulatedLoadEvents) async {
  var uniqFamily = '${cfg.family}_${useSimulatedLoadEvents}';
  print('  > Start Loading $uniqFamily ${useSimulatedLoadEvents ? "simulated" : "native"}');
  var ffo = new FontFaceObserver(uniqFamily, useSimulatedLoadEvents: useSimulatedLoadEvents, timeout: 500);
  var result = await ffo.load(cfg.url);
  print('  * $result');
  var message = cfg.testString;
  
  TableRowElement row = new TableRowElement();
  TableElement table = document.getElementById('table');
  row.append(new TableCellElement()..text = uniqFamily);
  row.append(new TableCellElement()..text = useSimulatedLoadEvents ? "Simulated" : "FontFace");
  row.append(new TableCellElement()..text = result.isLoaded ? 'Yes' : 'No');

  var pass = cfg.expectLoad ? result.isLoaded : !result.isLoaded;
  
  row.append(new TableCellElement()..text = pass ? 'Yes' : 'No'..style.backgroundColor = pass ? 'green' : 'red');

  row.append(new TableCellElement()..append(new DivElement()
    ..text = message
    ..style.fontFamily = uniqFamily
    ..style.fontSize = '18px'
  ));
  CanvasElement canvas = new CanvasElement();
  canvas.width = 400;
  canvas.height = 35;
  row.append(new TableCellElement()..append(canvas));
  table.append(row);

  drawTextToCanvas(message, uniqFamily, canvas);
  print('  > Done Loading ${uniqFamily}');
}

main() async {
  print('1. writing support');
  writeSupport();
  int i = 0;
  for (; i < fonts.length; i++) {
    var cfg = fonts[i];
    print('${i+2}. Loading ${cfg.family}');
    await loadFont(cfg, cfg.useSimulatedLoadEvents);
  }
  print('Done');
}
