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
import 'dart:html';

typedef void _OnScrollCallback(num width);

class Ruler {
  DivElement element;
  SpanElement collapsible;
  SpanElement expandable;
  SpanElement collapsibleInner;
  SpanElement expandableInner;
  int lastOffsetWidth = -1;
  String text;

  Ruler(String this.text) {
    element = document.createElement('div');
    element.setAttribute('aria-hidden', 'true');
    element.text = text;

    collapsible = new SpanElement();
    expandable = new SpanElement();
    collapsibleInner = new SpanElement();
    expandableInner = new SpanElement();

    _styleElement(collapsible);
    _styleElement(expandable);
    _styleElement(expandableInner);
    collapsibleInner.style
      ..display = 'inline-block'
      ..width = '200%'
      ..height = '200%'
      ..fontSize = '16px'
      ..maxWidth = 'none';

    collapsible.append(collapsibleInner);
    expandable.append(expandableInner);
    element.append(collapsible);
    element.append(expandable);
  }

  _styleElement(HtmlElement element) {
    element.style
      ..maxWidth = 'none'
      ..display = 'inline-block'
      ..position = 'absolute'
      ..height = '100%'
      ..width = '100%'
      ..overflow = 'scroll'
      ..fontSize = '16px';
  }

  setFont(String font) {
    element.style
      ..maxWidth = 'none'
      ..minWidth = '20px'
      ..display = 'inline-block'
      ..overflow = 'hidden'
      ..position = 'absolute'
      ..width = 'auto'
      ..margin = '0'
      ..padding = '0'
      ..top = '-999px'
      ..left = '-999px'
      ..whiteSpace = 'nowrap'
      ..font = font;
  }

  int getWidth() {
    return element.offsetWidth;
  }

  setWidth(width) {
    element.style.width = '${width}px';
  }

  bool reset() {
    var offsetWidth = element.offsetWidth;
    var width = offsetWidth + 100;

    expandableInner.style.width = '${width}px';
    expandable.scrollLeft = width;
    collapsible.scrollLeft = collapsible.scrollWidth + 100;

    if (lastOffsetWidth != offsetWidth) {
      lastOffsetWidth = offsetWidth;
      return true;
    } else {
      return false;
    }
  }

  onScroll(_OnScrollCallback callback) {
    if (reset() && element.parentNode != null) {
      callback(lastOffsetWidth);
    }
  }

  onResize(_OnScrollCallback callback) {
    collapsible.onScroll.listen((ev) {
      onScroll(callback);
    });
    expandable.onScroll.listen((ev) {
      onScroll(callback);
    });
    reset();
  }
}
