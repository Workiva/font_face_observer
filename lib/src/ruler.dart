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

typedef void _OnScrollCallback(num width);

/// The CSS class name to add to temporary DOM nodes used when detecting
/// font load.
const String fontFaceObserverTempClassname = '_ffo_temp';

/// A Ruler measures text and then observes for when the size changes due to
/// a font being loaded.
class Ruler {
  /// The element in the DOM that this ruler is using to measure
  Element element;
  SpanElement _collapsible;
  SpanElement _expandable;
  SpanElement _collapsibleInner;
  SpanElement _expandableInner;
  int _lastOffsetWidth = -1;

  /// The test string to use when measuring
  String text;

  List<StreamSubscription<Event>> _subscriptions =
      <StreamSubscription<Event>>[];

  /// Construct a Ruler with a given test string [text]
  Ruler(this.text) {
    element = document.createElement('div')
      ..className = 'font_face_ruler_div'
      ..setAttribute('aria-hidden', 'true')
      ..text = text;

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
    element..append(_collapsible)..append(_expandable);
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
  int getWidth() => element.offsetWidth;

  /// Set the width of [element] using an inline style
  void setWidth(num width) {
    element.style.width = '${width}px';
  }

  bool _reset() {
    final int offsetWidth = element.offsetWidth;
    final int width = offsetWidth + 100;

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
    _subscriptions
      ..add(_collapsible.onScroll.listen((Event _) {
        _onScroll(callback);
      }))
      ..add(_expandable.onScroll.listen((Event _) {
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
