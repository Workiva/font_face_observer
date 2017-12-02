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
import 'package:font_face_observer/font_face_observer.dart';
import 'package:font_face_observer/support.dart';
import 'package:font_face_observer/src/adobe_blank.dart';

const String _successMessage = 'Pack my box with five dozen liquor jugs';

class _FontConfig {
  String url;
  String family;
  String testString;
  bool useSimulatedLoadEvents;
  bool expectLoad;
  _FontConfig({this.family, this.url, this.testString: _successMessage, this.expectLoad: true, this.useSimulatedLoadEvents: false });
}

final List<_FontConfig> _fonts = new List<_FontConfig>()
  ..add(new _FontConfig(family: 'AdobeBlank', url: adobeBlankFontBase64Url))
  ..add(new _FontConfig(family: 'AdobeBlank', url: adobeBlankFontBase64Url, useSimulatedLoadEvents: true))
  ..add(new _FontConfig(family: 'Roboto', url: '/fonts/Roboto.ttf'))
  ..add(new _FontConfig(family: 'Roboto', url: '/fonts/Roboto.ttf', useSimulatedLoadEvents: true))
  ..add(new _FontConfig(family: 'Wdesk_Icons', url: '/fonts/Wdesk_Icons.ttf',testString: '\uE600 \uE601'))
  ..add(new _FontConfig(family: 'Wdesk_Icons', url: '/fonts/Wdesk_Icons.ttf',testString: '\uE600 \uE601', useSimulatedLoadEvents: true))
  ..add(new _FontConfig(family: 'Wdesk_Doctype-Icons', url: '/fonts/Wdesk_Doctype-Icons.ttf', testString: '\uE6D9 \uE026'))
  ..add(new _FontConfig(family: 'Wdesk_Doctype-Icons', url: '/fonts/Wdesk_Doctype-Icons.ttf', testString: '\uE6D9 \uE026', useSimulatedLoadEvents: true))
  ..add(new _FontConfig(family: 'Subset', url: '/fonts/subset.ttf', testString: '\u25FC \u4E2D \u56FD'))
  ..add(new _FontConfig(family: 'Subset', url: '/fonts/subset.ttf', testString: '\u25FC \u4E2D \u56FD', useSimulatedLoadEvents: true))
  ..add(new _FontConfig(family: 'empty', url: '/fonts/empty.otf', expectLoad: true, testString: '', useSimulatedLoadEvents: true))
  ..add(new _FontConfig(family: 'W', url: '/fonts/W.ttf', testString: '\uE0FF'))
  ..add(new _FontConfig(family: 'W', url: '/fonts/W.ttf', testString: '\uE0FF', useSimulatedLoadEvents: true));

void _drawTextToCanvas(String text, String fontName, CanvasElement canvas) {  
  // ignore: avoid_as
  CanvasRenderingContext2D ctx = canvas.getContext('2d') as CanvasRenderingContext2D;
  ctx.setFillColorRgb(255, 255, 255);
  ctx.fillRect(0,0, canvas.width, canvas.height);
  ctx.setFillColorRgb(0, 0, 0);
  ctx.font = '18px $fontName';
  ctx.fillText(text, 5, 28);
}

void _writeSupport() {
  String supportString = '''
supportsStretch: $supportsStretch
supportsNativeFontLoading: $supportsNativeFontLoading
hasWebKitFallbackBug: $hasWebkitFallbackBug
  ''';
  document.getElementById('supports').text = supportString;
  print(supportString);
}

Future<Null> _loadFont(_FontConfig cfg, bool useSimulatedLoadEvents) async {
  String uniqFamily = '${cfg.family}_${useSimulatedLoadEvents}';
  print('  > Start Loading $uniqFamily ${useSimulatedLoadEvents ? "simulated" : "native"}');
  FontFaceObserver ffo = new FontFaceObserver(uniqFamily, useSimulatedLoadEvents: useSimulatedLoadEvents, timeout: 500);
  FontLoadResult result = await ffo.load(cfg.url);
  print('  * $result');
  String message = cfg.testString;
  
  TableRowElement row = new TableRowElement();
  Element table = document.getElementById('table');
  row.append(new TableCellElement()..text = uniqFamily);
  row.append(new TableCellElement()..text = useSimulatedLoadEvents ? "Simulated" : "FontFace");
  row.append(new TableCellElement()..text = result.isLoaded ? 'Yes' : 'No');

  bool pass = cfg.expectLoad ? result.isLoaded : !result.isLoaded;
  
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

  _drawTextToCanvas(message, uniqFamily, canvas);
  print('  > Done Loading ${uniqFamily}');
}

Future<Null> main() async {
  print('1. writing support');
  _writeSupport();
  int i = 0;
  for (; i < _fonts.length; i++) {
    _FontConfig cfg = _fonts[i];
    print('${i+2}. Loading ${cfg.family}');
    await _loadFont(cfg, cfg.useSimulatedLoadEvents);
  }
  print('Done');
}
