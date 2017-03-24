import 'dart:html';
import 'dart:async';
import 'package:font_face_observer/font_face_observer.dart';

String groupName = "group_A";
var cfg = new FontConfig(family: 'Roboto_1', url: '/fonts/Roboto.ttf', useSimulatedLoadEvents: true);
var cfg2 = new FontConfig(family: 'Roboto_2', url: '/fonts/Roboto.ttf', group: groupName);
var cfg3 = new FontConfig(family: 'Roboto_3', url: '/fonts/Roboto.ttf', group: groupName);

ButtonElement unloadButton = document.getElementById('unloadBtn');
ButtonElement unloadGroupButton = document.getElementById('unloadGroupBtn');
ButtonElement loadButton = document.getElementById('loadBtn');

class FontConfig {
  String url;
  String family;
  String group;
  bool useSimulatedLoadEvents;
  bool expectLoad;
  FontConfig({this.family, this.url, this.useSimulatedLoadEvents: false, this.group});
  String key;
}

loadFont(FontConfig cfg) async {
  var ffo = new FontFaceObserver(cfg.family, useSimulatedLoadEvents: cfg.useSimulatedLoadEvents, timeout: 500, group: cfg.group);
  cfg.key = ffo.key;
  await ffo.load(cfg.url);
}

bool unloadFont(FontConfig cfg) {
  return FontFaceObserver.unload(cfg.key);
}

unload(_) {
  FontFaceObserver.unload(cfg.key);
  updateCounts();
}

unloadGroup(_) {
  FontFaceObserver.unloadGroup(groupName);
  updateCounts();
}

load(_) async {
  await loadFont(cfg);
  updateCounts();
  await loadFont(cfg2);
  updateCounts();
  await loadFont(cfg3);
  updateCounts();
}

updateCounts() {
  int n = querySelectorAll('._ffo_temp').length;
  document.getElementById('ffo_temp_elements').innerHtml = n.toString();

  n = querySelectorAll('style._ffo').length;
  document.getElementById('ffo_elements').innerHtml = n.toString();
}

main() async {
  loadButton.onClick.listen(load);
  unloadButton.onClick.listen(unload);
  unloadGroupButton.onClick.listen(unloadGroup);
  updateCounts();
}
