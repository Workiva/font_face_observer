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
@TestOn('browser')
import 'dart:async';
import 'dart:html';
import 'package:test/test.dart';
import 'package:font_face_observer/font_face_observer.dart';
import 'package:font_face_observer/src/adobe_blank.dart';

class _FontUrls {
  static const String roboto = 'fonts/Roboto.ttf';
  static const String w = 'fonts/W.ttf';
  static const String empty = 'fonts/empty.ttf';
  static const String subset = 'fonts/subset.ttf';
  static const String fontNotFound = 'fonts/font_not_found.ttf';
}

void main() {
  group('FontFaceObserver', () {
    tearDown(() async {
      while (FontFaceObserver.getLoadedGroups().isNotEmpty) {
        for (String group in FontFaceObserver.getLoadedGroups()) {
          await FontFaceObserver.unloadGroup(group);
        }
      }
    });

    void expectKeyNotLoaded(String key) {
      expect(querySelector('style[data-key="${key}"]'), isNull);
      expect(querySelector('span[data-key="${key}"]'), isNull);
      expect(FontFaceObserver.getLoadedFontKeys().contains(key), isFalse);
    }

    void expectGroupNotLoaded(String group) {
      expect(FontFaceObserver.getLoadedGroups().contains(group), isFalse);
    }

    test('should handle quoted family name', () {
      expect(new FontFaceObserver('"my family"').family, equals('my family'));
      expect(new FontFaceObserver("'my family'").family, equals('my family'));
      expect(new FontFaceObserver('my family').family, equals('my family'));
    });

    test('should init correctly with passed in values', () {
      const String family = 'my family';
      const String style = 'my style';
      const String weight = 'my weight';
      const String stretch = 'my stretch';
      const String testString = 'my testString';
      const int timeout = 1337;

      final FontFaceObserver ffo = new FontFaceObserver(family,
          style: style,
          weight: weight,
          stretch: stretch,
          testString: testString,
          useSimulatedLoadEvents: true,
          timeout: timeout);
      expect(ffo, isNotNull);
      expect(ffo.family, equals(family));
      expect(ffo.style, equals(style));
      expect(ffo.weight, equals(weight));
      expect(ffo.stretch, equals(stretch));
      expect(ffo.testString, equals(testString));
      expect(ffo.timeout, equals(timeout));
      expect(ffo.useSimulatedLoadEvents, equals(true));
      ffo.testString = '  ';
      expect(ffo.testString, equals('BESbswy'));
    });

    test('should timeout and fail for a bogus font when using FontFace API',
        () async {
      final FontLoadResult result =
          await new FontFaceObserver('bogus', timeout: 500)
              .load(_FontUrls.fontNotFound);
      expect(result.isLoaded, isFalse);
      expect(result.didTimeout, isTrue);
    });

    test('should detect a bogus font with simulated events', () async {
      final FontLoadResult result = await new FontFaceObserver('bogus2',
              timeout: 100, useSimulatedLoadEvents: true)
          .load(_FontUrls.fontNotFound);
      expect(result.isLoaded, isTrue);
      expect(result.didTimeout, isFalse);
    });

    test('should load a real font', () async {
      final FontLoadResult result =
          await new FontFaceObserver('test1').load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
    });

    test('should load a real font using simulated events', () async {
      final FontFaceObserver ffo =
          new FontFaceObserver('test2', useSimulatedLoadEvents: true);
      FontLoadResult result = await ffo.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      result = await ffo.check();
      expect(result.isLoaded, isTrue);
    });

    test('should track the font keys and groups correctly', () async {
      await new FontFaceObserver('font_keys1').load(_FontUrls.roboto);
      await new FontFaceObserver('font_keys2').load(_FontUrls.roboto);
      await new FontFaceObserver('font_keys3', group: 'group_1')
          .load(_FontUrls.roboto);
      await new FontFaceObserver('font_keys4', group: 'group_2')
          .load(_FontUrls.roboto);

      // AdobeBlank is always loaded, so expect that too
      final Iterable<String> keys = FontFaceObserver.getLoadedFontKeys();
      expect(keys.length, equals(5));
      expect(keys.contains('font_keys1_normal_normal_normal'), isTrue);
      expect(keys.contains('font_keys2_normal_normal_normal'), isTrue);
      expect(keys.contains('font_keys3_normal_normal_normal'), isTrue);
      expect(keys.contains('font_keys4_normal_normal_normal'), isTrue);
      expect(keys.contains(adobeBlankKey), isTrue);

      // expect the default group too
      final Iterable<String> groups = FontFaceObserver.getLoadedGroups();
      expect(groups.length, equals(4));
      expect(groups.contains(FontFaceObserver.defaultGroup), isTrue);
      expect(groups.contains('group_1'), isTrue);
      expect(groups.contains('group_2'), isTrue);
      expect(groups.contains(adobeBlankFamily), isTrue);
    });

    test('should not leave temp DOM nodes after detecting', () async {
      final FontFaceObserver ffo =
          new FontFaceObserver('no_dom_leaks', useSimulatedLoadEvents: true);
      final FontLoadResult result = await ffo.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      final ElementList<Element> elements = querySelectorAll('._ffo_temp');
      if (elements.isNotEmpty) {
        for (Element el in elements) {
          print('${el.tagName}.${el.className}');
        }
      }
      expect(elements.length, isZero);
    });

    test('should unload a font by key', () async {
      final FontFaceObserver ffo = new FontFaceObserver('unload_by_key');
      final String key = ffo.key;
      final FontLoadResult result = await ffo.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      await FontFaceObserver.unload(key, ffo.group);
      final Element styleElement = querySelector('style[data-key="${key}"]');
      expect(styleElement, isNull);
    });

    test('should use the default group if no group specified', () async {
      final FontFaceObserver ffo = new FontFaceObserver('default_group1');
      expect(ffo.group, equals(FontFaceObserver.defaultGroup));
    });

    test('should unload a font by group', () async {
      const String group = 'somegroup';
      await new FontFaceObserver('unload_by_group1', group: group)
          .load(_FontUrls.roboto);
      await new FontFaceObserver('unload_by_group2', group: group)
          .load(_FontUrls.roboto);
      await FontFaceObserver.unloadGroup(group);
      expect(querySelectorAll('style[data-group="${group}"]').length, isZero);
    });

    test('should keep data-uses attribute up to date', () async {
      const String differentGroup = 'diff';
      final FontFaceObserver ffo = new FontFaceObserver('uses_test');
      final String key = ffo.key;
      FontLoadResult result = await ffo.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      final Element styleElement = querySelector('style[data-key="${key}"]');
      expect(styleElement.dataset['uses'], '1');

      // load it again with the same group, uses should be 2
      result = await ffo.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      expect(styleElement.dataset['uses'], '2');

      // load it again with a different group, uses should be 3
      final FontFaceObserver ffo2 =
          new FontFaceObserver('uses_test', group: differentGroup);
      result = await ffo2.load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
      expect(styleElement.dataset['uses'], '3');

      // unload it once with the default group
      expect(await FontFaceObserver.unload(key, ffo.group), isTrue);
      expect(styleElement.dataset['uses'], '2');

      // unload the font from the 2nd ffo
      expect(await FontFaceObserver.unload(ffo2.key, ffo2.group), isTrue);
      expect(styleElement.dataset['uses'], '1');

      // unload it completely
      expect(await FontFaceObserver.unload(key, ffo.group), isTrue);

      // unload it again, should not go negative
      expect(await FontFaceObserver.unload(key, ffo.group), isFalse);
      expect(querySelector('style[data-key="${key}"]'), isNull);
      expect(querySelector('span[data-key="${key}"]'), isNull);
      expect(styleElement.dataset['uses'], '0');
    });

    test('should timeout on an empty font, not throw an exception', () async {
      final FontLoadResult result =
          await new FontFaceObserver('empty1', timeout: 100)
              .load(_FontUrls.empty);
      expect(result.isLoaded, isFalse);
      expect(result.didTimeout, isTrue);
    });

    test(
        'should detect an empty font, not throw an exception with simulated events',
        () async {
      final FontLoadResult result = await new FontFaceObserver('empty2',
              timeout: 100, useSimulatedLoadEvents: true)
          .load(_FontUrls.empty);
      expect(result.isLoaded, isTrue);
      expect(result.didTimeout, isFalse);
    });

    test('should load user-region-only font', () async {
      final FontLoadResult result =
          await new FontFaceObserver('w', timeout: 100, testString: '\uE0FF')
              .load(_FontUrls.w); // 57599
      expect(result.isLoaded, isTrue);
      expect(result.didTimeout, isFalse);
    });

    test('should find the font if it is already loaded', () async {
      await new FontFaceObserver('test3').load(_FontUrls.roboto);
      final FontLoadResult result = await new FontFaceObserver('test3').check();
      expect(result.isLoaded, isTrue);
    });

    test('should cleanup when not successful', () async {
      final FontFaceObserver ffo1 =
          new FontFaceObserver('cleanup1', timeout: 100, group: 'group1');
      final FontFaceObserver ffo2 =
          new FontFaceObserver('cleanup2', timeout: 100, group: 'group2');

      final FontLoadResult result1 = await ffo1.load(_FontUrls.empty);
      final FontLoadResult result2 = await ffo2.load(_FontUrls.fontNotFound);

      expect(result1.isLoaded, isFalse);
      expect(result2.isLoaded, isFalse);
      expectKeyNotLoaded(ffo1.key);
      expectKeyNotLoaded(ffo2.key);
      expectGroupNotLoaded(ffo1.group);
      expectGroupNotLoaded(ffo2.group);
    });

    test('should handle async interleaved load and unload calls', () async {
      final FontFaceObserver ffo1 =
          new FontFaceObserver('complex1', group: 'group1');

      // fire this off async
      final Future<FontLoadResult> f1 = ffo1.load(_FontUrls.roboto);
      await FontFaceObserver.unloadGroup(ffo1.group);
      await f1;
      expectKeyNotLoaded(ffo1.key);
      expectGroupNotLoaded(ffo1.group);
    });

    test('should handle spaces and numbers in font family', () async {
      final FontLoadResult result =
          await new FontFaceObserver('Garamond 7').load(_FontUrls.roboto);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range within ASCII',
        () async {
      final FontLoadResult result =
          await new FontFaceObserver('unicode1', testString: '\u0021')
              .load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });

    test(
        'should find a font with a custom unicode range outside ASCII (but within BMP)',
        () async {
      final FontLoadResult result =
          await new FontFaceObserver('unicode2', testString: '\u4e2d\u56fd')
              .load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside the BMP',
        () async {
      final FontLoadResult result =
          await new FontFaceObserver('unicode3', testString: '\udbff\udfff')
              .load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });

    test(
        'should find a font with a custom unicode range within ASCII with simulated events',
        () async {
      final FontLoadResult result = await new FontFaceObserver('unicode1',
              testString: '\u0021', useSimulatedLoadEvents: true)
          .load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });

    test(
        'should find a font with a custom unicode range outside ASCII (but within BMP) with simulated events',
        () async {
      final FontLoadResult result = await new FontFaceObserver('unicode2',
              testString: '\u4e2d\u56fd', useSimulatedLoadEvents: true)
          .load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });

    test(
        'should find a font with a custom unicode range outside the BMP with simulated events',
        () async {
      final FontLoadResult result = await new FontFaceObserver('unicode3',
              testString: '\udbff\udfff', useSimulatedLoadEvents: true)
          .load(_FontUrls.subset);
      expect(result.isLoaded, isTrue);
    });
  });
}
