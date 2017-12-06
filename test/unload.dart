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
import 'dart:html';
import 'dart:async';
import 'package:font_face_observer/font_face_observer.dart';

String _groupA = "group_A";
String _groupB = "group_B";
_FontConfig _cfg = new _FontConfig(family: 'Roboto_1', url: '/fonts/Roboto.ttf', useSimulatedLoadEvents: true);
_FontConfig _cfg2 = new _FontConfig(family: 'Roboto_2', url: '/fonts/Roboto.ttf', group: _groupA);
_FontConfig _cfg3 = new _FontConfig(family: 'Roboto_3', url: '/fonts/Roboto.ttf', group: _groupA);
_FontConfig _cfg4 = new _FontConfig(family: 'Roboto_2', url: '/fonts/Roboto.ttf', group: _groupB);

Element _unloadButton = document.getElementById('unloadBtn');
Element _unloadGroupButton = document.getElementById('unloadGroupBtn');
Element _unloadGroupButtonB = document.getElementById('unloadGroupBtnB');
Element _loadButton = document.getElementById('loadBtn');
Element _asyncBtn = document.getElementById('asyncBtn');

class _FontConfig {
  String url;
  String family;
  String group;
  bool useSimulatedLoadEvents;
  bool expectLoad;
  _FontConfig({this.family, this.url, this.useSimulatedLoadEvents: false, this.group: FontFaceObserver.defaultGroup});
  String key;
}

Future<FontLoadResult> _loadFont(_FontConfig cfg) async {
  FontFaceObserver ffo = new FontFaceObserver(cfg.family, useSimulatedLoadEvents: cfg.useSimulatedLoadEvents, group: cfg.group);
  cfg.key = ffo.key;
  return ffo.load(cfg.url);
}

Future<Null> _unload(Event _) async {
  await FontFaceObserver.unload(_cfg.key, _cfg.group);
  _updateCounts();
}

Future<Null> _unloadGroup(String group) async {
  await FontFaceObserver.unloadGroup(group);
  _updateCounts();
}

Future<Null> _load(Event _) async {
  await _loadFont(_cfg);
  _updateCounts();
  await _loadFont(_cfg2);
  _updateCounts();
  await _loadFont(_cfg3);
  _updateCounts();
  await _loadFont(_cfg4);
  _updateCounts();
}

void _updateCounts() {
  int n = querySelectorAll('._ffo_temp').length;
  document.getElementById('ffo_temp_elements').innerHtml = n.toString();

  n = querySelectorAll('style._ffo').length;
  document.getElementById('ffo_elements').innerHtml = n.toString();

  document.getElementById('ffo_keys').innerHtml = FontFaceObserver.getLoadedFontKeys().toString();
  document.getElementById('ffo_groups').innerHtml = FontFaceObserver.getLoadedGroups().toString();
}
Future<Null> _asyncLoadUnload() async {
  FontFaceObserver ffo1 = new FontFaceObserver(_cfg2.family, useSimulatedLoadEvents: _cfg2.useSimulatedLoadEvents, group: _cfg2.group);

  // fire this off async
  Future<FontLoadResult> f1 = ffo1.load(_cfg2.url);
  await FontFaceObserver.unloadGroup(ffo1.group);
  await f1;
  // The font should be unloaded
  _updateCounts();
}

Future<Null> main() async {
  _loadButton.onClick.listen(_load);
  _unloadButton.onClick.listen(_unload);
  _unloadGroupButton.onClick.listen((_) => _unloadGroup(_groupA));
  _unloadGroupButtonB.onClick.listen((_) => _unloadGroup(_groupB));
  _asyncBtn.onClick.listen((_) => _asyncLoadUnload());
  _updateCounts();
}
