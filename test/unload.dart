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
ButtonElement asyncBtn = document.getElementById('asyncBtn');

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
  await FontFaceObserver.unload(cfg.key, cfg.group);
  updateCounts();
}

unloadGroup(group) async {
  await FontFaceObserver.unloadGroup(group);
  updateCounts();
}

load(_) async {
  // await Future.wait([loadFont(cfg), loadFont(cfg2), loadFont(cfg3), loadFont(cfg4)]);
  await loadFont(cfg);
  updateCounts();
  await loadFont(cfg2);
  updateCounts();
  await loadFont(cfg3);
  updateCounts();
  await loadFont(cfg4);
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
asyncLoadUnload() async {
  var ffo1 = new FontFaceObserver(cfg2.family, useSimulatedLoadEvents: cfg2.useSimulatedLoadEvents, group: cfg2.group);
  var ffo2 = new FontFaceObserver(cfg3.family, useSimulatedLoadEvents: cfg3.useSimulatedLoadEvents, group: cfg3.group);
  var ffo3 = new FontFaceObserver(cfg4.family, useSimulatedLoadEvents: cfg4.useSimulatedLoadEvents, group: cfg4.group);

  // fire this off async
  var f1 = ffo1.load(cfg2.url);
  await FontFaceObserver.unloadGroup(ffo1.group);
  await f1;
}
main() async {
  loadButton.onClick.listen(load);
  unloadButton.onClick.listen(unload);
  unloadGroupButton.onClick.listen((_) => unloadGroup(groupA));
  unloadGroupButtonB.onClick.listen((_) => unloadGroup(groupB));
  asyncBtn.onClick.listen((_) => asyncLoadUnload());
  updateCounts();
}
