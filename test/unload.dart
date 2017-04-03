import 'dart:html';
import 'dart:async';
import 'package:font_face_observer/font_face_observer.dart';

String groupA = "group_A";
String groupB = "group_B";
var cfg = new FontConfig(family: 'Roboto_1', url: '/fonts/Roboto.ttf', useSimulatedLoadEvents: true);
var cfg2 = new FontConfig(family: 'Roboto_2', url: '/fonts/Roboto.ttf', group: groupA);
var cfg3 = new FontConfig(family: 'Roboto_3', url: '/fonts/Roboto.ttf', group: groupA);
var cfg4 = new FontConfig(family: 'Roboto_2', url: '/fonts/Roboto.ttf', group: groupB);

ButtonElement unloadButton = document.getElementById('unloadBtn');
ButtonElement unloadGroupButton = document.getElementById('unloadGroupBtn');
ButtonElement unloadGroupButtonB = document.getElementById('unloadGroupBtnB');
ButtonElement loadButton = document.getElementById('loadBtn');

class FontConfig {
  String url;
  String family;
  String group;
  bool useSimulatedLoadEvents;
  bool expectLoad;
  FontConfig({this.family, this.url, this.useSimulatedLoadEvents: false, this.group: FontFaceObserver.defaultGroup});
  String key;
}

Future loadFont(FontConfig cfg) async {
  var ffo = new FontFaceObserver(cfg.family, useSimulatedLoadEvents: cfg.useSimulatedLoadEvents, group: cfg.group);
  cfg.key = ffo.key;
  return ffo.load(cfg.url);
}

unload(_) async {
  await FontFaceObserver.unload(cfg.key);
  updateCounts();
}

unloadGroup(group) async {
  await FontFaceObserver.unloadGroup(group);
  updateCounts();
}

load(_) async {
  await Future.wait([loadFont(cfg), loadFont(cfg2), loadFont(cfg3), loadFont(cfg4)]);
  // await loadFont(cfg);
  // updateCounts();
  // await loadFont(cfg2);
  // updateCounts();
  // await loadFont(cfg3);
  updateCounts();
}

updateCounts() {
  int n = querySelectorAll('._ffo_temp').length;
  document.getElementById('ffo_temp_elements').innerHtml = n.toString();

  n = querySelectorAll('style._ffo').length;
  document.getElementById('ffo_elements').innerHtml = n.toString();

  document.getElementById('ffo_keys').innerHtml = FontFaceObserver.getLoadedFontKeys().toString();
  document.getElementById('ffo_groups').innerHtml = FontFaceObserver.getLoadedGroups().toString();
}

main() async {
  loadButton.onClick.listen(load);
  unloadButton.onClick.listen(unload);
  unloadGroupButton.onClick.listen((_) => unloadGroup(groupA));
  unloadGroupButtonB.onClick.listen((_) => unloadGroup(groupB));
  updateCounts();
}
