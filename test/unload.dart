import 'dart:html';
import 'dart:async';
import 'package:font_face_observer/font_face_observer.dart';

String _groupA = "group_A";
String _groupB = "group_B";
_FontConfig _cfg = new _FontConfig(family: 'Roboto_1', url: '/fonts/Roboto.ttf', useSimulatedLoadEvents: true);
_FontConfig _cfg2 = new _FontConfig(family: 'Roboto_2', url: '/fonts/Roboto.ttf', group: _groupA);
_FontConfig _cfg3 = new _FontConfig(family: 'Roboto_3', url: '/fonts/Roboto.ttf', group: _groupA);
_FontConfig _cfg4 = new _FontConfig(family: 'Roboto_2', url: '/fonts/Roboto.ttf', group: _groupB);

ButtonElement _unloadButton = document.getElementById('unloadBtn');
ButtonElement _unloadGroupButton = document.getElementById('unloadGroupBtn');
ButtonElement _unloadGroupButtonB = document.getElementById('unloadGroupBtnB');
ButtonElement _loadButton = document.getElementById('loadBtn');
ButtonElement _asyncBtn = document.getElementById('asyncBtn');

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

Future<Null> _unload(_) async {
  await FontFaceObserver.unload(_cfg.key, _cfg.group);
  _updateCounts();
}

Future<Null> _unloadGroup(String group) async {
  await FontFaceObserver.unloadGroup(group);
  _updateCounts();
}

Future<Null> _load(_) async {
  // await Future.wait([loadFont(cfg), loadFont(cfg2), loadFont(cfg3), loadFont(cfg4)]);
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
}

Future<Null> main() async {
  _loadButton.onClick.listen(_load);
  _unloadButton.onClick.listen(_unload);
  _unloadGroupButton.onClick.listen((_) => _unloadGroup(_groupA));
  _unloadGroupButtonB.onClick.listen((_) => _unloadGroup(_groupB));
  _asyncBtn.onClick.listen((_) => _asyncLoadUnload());
  _updateCounts();
}
