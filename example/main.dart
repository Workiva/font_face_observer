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
import 'package:font_face_observer/font_face_observer.dart';
import 'package:font_face_observer/support.dart';

const String _successMessage = 'Pack my box with five dozen liquor jugs';

class _FontConfig {
  String url;
  String family;
  String testString;
  bool expectLoad;
  _FontConfig(
      {required this.family,
      required this.url,
      this.testString = _successMessage,
      this.expectLoad = true});
}

final List<_FontConfig> _fonts = <_FontConfig>[]
  ..add(_FontConfig(family: 'Roboto', url: '/fonts/Roboto.ttf'))
  ..add(_FontConfig(
      family: 'Wdesk_Icons',
      url: '/fonts/Wdesk_Icons.ttf',
      testString: '\uE600 \uE601'))
  ..add(_FontConfig(
      family: 'Wdesk_Doctype-Icons',
      url: '/fonts/Wdesk_Doctype-Icons.ttf',
      testString: '\uE6D9 \uE026'))
  ..add(_FontConfig(
      family: 'Subset',
      url: '/fonts/subset.ttf',
      testString: '\u25FC \u4E2D \u56FD'));

void _drawTextToCanvas(String text, String fontName, CanvasElement canvas) {
  // ignore: avoid_as
  canvas.getContext('2d') as CanvasRenderingContext2D
    ..setFillColorRgb(255, 255, 255)
    ..fillRect(0, 0, canvas.width!, canvas.height!)
    ..setFillColorRgb(0, 0, 0)
    ..font = '18px $fontName'
    ..fillText(text, 5, 28);
}

void _writeSupport() {
  final String supportString = '''
supportsStretch: $supportsStretch
supportsNativeFontLoading: $supportsNativeFontLoading
  ''';
  document.getElementById('supports')!.text = supportString;
  print(supportString);
}

Future<Null> _loadFont(_FontConfig cfg) async {
  final String uniqFamily = cfg.family;
  print('  > Start Loading $uniqFamily');
  final FontFaceObserver ffo = FontFaceObserver(uniqFamily, timeout: 500);
  final FontLoadResult result = await ffo.load(cfg.url);
  final bool pass = cfg.expectLoad ? result.isLoaded : !result.isLoaded;
  print('  * $result');
  final String message = cfg.testString;

  final Element table = document.getElementById('table')!;

  final CanvasElement canvas = CanvasElement()
    ..width = 400
    ..height = 35;
  final TableRowElement row = TableRowElement()
    ..append(TableCellElement()..text = uniqFamily)
    ..append(TableCellElement()..text = 'FontFace')
    ..append(TableCellElement()..text = result.isLoaded ? 'Yes' : 'No')
    ..append(TableCellElement()
      ..text = pass ? 'Yes' : 'No'
      ..style.backgroundColor = pass ? 'green' : 'red')
    ..append(TableCellElement()
      ..append(DivElement()
        ..text = message
        ..style.fontFamily = uniqFamily
        ..style.fontSize = '18px'))
    ..append(TableCellElement()..append(canvas));
  table.append(row);

  _drawTextToCanvas(message, uniqFamily, canvas);
  print('  > Done Loading ${uniqFamily}');
}

Future<Null> main() async {
  print('1. writing support');
  _writeSupport();
  int i = 0;
  for (; i < _fonts.length; i++) {
    final _FontConfig cfg = _fonts[i];
    print('${i + 2}. Loading ${cfg.family}');
    await _loadFont(cfg);
  }
  print('Done');
}
