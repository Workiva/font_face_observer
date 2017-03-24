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

const String fontFaceObserverTempClassname = '_ffo_temp';

class Ruler {
  DivElement element;
  SpanElement _collapsible;
  SpanElement _expandable;
  SpanElement _collapsibleInner;
  SpanElement _expandableInner;
  int _lastOffsetWidth = -1;
  String text;

  Ruler(String this.text) {
    element = document.createElement('div');
    element.className = 'font_face_ruler_div';
    element.setAttribute('aria-hidden', 'true');
    element.text = text;

    _collapsible = new SpanElement();
    _expandable = new SpanElement();
    _collapsibleInner = new SpanElement();
    _expandableInner = new SpanElement();
    _collapsible.className = '$fontFaceObserverTempClassname ffo_ruler_span_collapsible';
    _collapsibleInner.className = '$fontFaceObserverTempClassname ffo_ruler_span_collapsibleInner';
    _expandable.className = '$fontFaceObserverTempClassname ffo_ruler_span_expandable';
    _expandableInner.className = '$fontFaceObserverTempClassname ffo_ruler_span_expandableInner';

    _styleElement(_collapsible);
    _styleElement(_expandable);
    _styleElement(_expandableInner);
    _collapsibleInner.style
      ..display = 'inline-block'
      ..width = '200%'
      ..height = '200%'
      ..fontSize = '16px'
      ..maxWidth = 'none';

    _collapsible.append(_collapsibleInner);
    _expandable.append(_expandableInner);
    element.append(_collapsible);
    element.append(_expandable);
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

    _expandableInner.style.width = '${width}px';
    _expandable.scrollLeft = width;
    _collapsible.scrollLeft = _collapsible.scrollWidth + 100;

    if (_lastOffsetWidth != offsetWidth) {
      _lastOffsetWidth = offsetWidth;
      return true;
    } else {
      return false;
    }
  }

  onScroll(_OnScrollCallback callback) {
    if (reset() && element.parentNode != null) {
      callback(_lastOffsetWidth);
    }
  }

  onResize(_OnScrollCallback callback) {
    _collapsible.onScroll.listen((ev) {
      onScroll(callback);
    });
    _expandable.onScroll.listen((ev) {
      onScroll(callback);
    });
    reset();
  }
}
