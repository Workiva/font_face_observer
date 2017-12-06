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
