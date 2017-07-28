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
import 'dart:async';

typedef void _OnScrollCallback(num width);

/// The CSS class name to add to temporary DOM nodes used when detecting
/// font load.
const String fontFaceObserverTempClassname = '_ffo_temp';

/// A Ruler measures text and then observes for when the size changes due to
/// a font being loaded.
class Ruler {
  /// The element in the DOM that this ruler is using to measure
  DivElement element;
  SpanElement _collapsible;
  SpanElement _expandable;
  SpanElement _collapsibleInner;
  SpanElement _expandableInner;
  int _lastOffsetWidth = -1;

  /// The test string to use when measuring
  String text;

  List<StreamSubscription<Event>> _subscriptions =
      new List<StreamSubscription<Event>>();

  /// Construct a Ruler with a given test string [text]
  Ruler(this.text) {
    element = document.createElement('div');
    element.className = 'font_face_ruler_div';
    element.setAttribute('aria-hidden', 'true');
    element.text = text;

    _collapsible = new SpanElement();
    _expandable = new SpanElement();
    _collapsibleInner = new SpanElement();
    _expandableInner = new SpanElement();
    // add class names for tracking nodes if they leak (and for testing)
    _collapsible.className =
        '$fontFaceObserverTempClassname _ffo_ruler_span_collapsible';
    _collapsibleInner.className =
        '$fontFaceObserverTempClassname _ffo_ruler_span_collapsibleInner';
    _expandable.className =
        '$fontFaceObserverTempClassname _ffo_ruler_span_expandable';
    _expandableInner.className =
        '$fontFaceObserverTempClassname _ffo_ruler_span_expandableInner';

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

  void _styleElement(HtmlElement element) {
    element.style
      ..maxWidth = 'none'
      ..display = 'inline-block'
      ..position = 'absolute'
      ..height = '100%'
      ..width = '100%'
      ..overflow = 'scroll'
      ..fontSize = '16px';
  }

  /// Sets the font to use for this ruler
  void setFont(String font) {
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

  /// queries the DOM to get the width of [element]
  int getWidth() {
    return element.offsetWidth;
  }

  /// Set the width of [element] using an inline style
  void setWidth(num width) {
    element.style.width = '${width}px';
  }

  bool _reset() {
    num offsetWidth = element.offsetWidth;
    num width = offsetWidth + 100;

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

  void _onScroll(_OnScrollCallback callback) {
    if (_reset() && element.parentNode != null) {
      callback(_lastOffsetWidth);
    }
  }

  /// Register a callback to be called when the ruler is resized
  void onResize(_OnScrollCallback callback) {
    _subscriptions.add(_collapsible.onScroll.listen((Event _) {
      _onScroll(callback);
    }));
    _subscriptions.add(_expandable.onScroll.listen((Event _) {
      _onScroll(callback);
    }));
    _reset();
  }

  /// Clean up when this ruler is no longer used
  void dispose() {
    for (StreamSubscription<Event> ss in _subscriptions) {
      ss.cancel();
    }
    _subscriptions.clear();
    _subscriptions = null;

    element?.remove();
    _collapsible?.remove();
    _expandable?.remove();
    _collapsibleInner?.remove();
    _expandableInner?.remove();

    element = null;
    _collapsible = null;
    _expandable = null;
    _collapsibleInner = null;
    _expandableInner = null;
  }
}
