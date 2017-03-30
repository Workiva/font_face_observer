@TestOn('browser')
import 'dart:html';
import 'package:test/test.dart';
import 'package:font_face_observer/font_face_observer.dart';
import 'package:font_face_observer/src/adobe_blank.dart';

class _FontUrls {
  static const String Roboto = 'fonts/Roboto.ttf';
  static const String W = 'fonts/W.ttf';
  static const String Empty = 'fonts/empty.ttf';
  static const String Subset = 'fonts/subset.ttf';
  static const String FontNotFound = 'fonts/font_not_found.ttf';
}

main() {
  group('FontFaceObserver', () {
    tearDown(() async {
      FontFaceObserver.getLoadedFontKeys().forEach((key) async => await FontFaceObserver.unload(key));
    });

    expectKeyNotLoaded(String key) {
      expect(querySelector('style[data-key="${key}"]'), isNull);
      expect(querySelector('span[data-key="${key}"]'), isNull);
      expect(FontFaceObserver.getLoadedFontKeys().contains(key), isFalse);
    }

    expectGroupNotLoaded(String group) {
      expect(FontFaceObserver.getLoadedGroups().contains(group), isFalse);
    }

    test('should handle quoted family name', () {
      expect(new FontFaceObserver('"my family"').family, equals('my family'));
      expect(new FontFaceObserver("'my family'").family, equals('my family'));
      expect(new FontFaceObserver("my family").family, equals('my family'));
    });

    test('should init correctly with passed in values', () {
      String family = 'my family';
      String style = 'my style';
      String weight = 'my weight';
      String stretch = 'my stretch';
      String testString = 'my testString';
      int timeout = 1337;

      var ffo = new FontFaceObserver(family,
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
    
    test('should timeout and fail for a bogus font when using FontFace API', () async {
      var result = await new FontFaceObserver('bogus', timeout: 500).load(_FontUrls.FontNotFound);
      expect(result.isLoaded, isFalse);
      expect(result.didTimeout, isTrue);
    });

    test('should detect a bogus font with simulated events', () async {
      var result = await new FontFaceObserver('bogus2', timeout: 100, useSimulatedLoadEvents: true).load(_FontUrls.FontNotFound);
      expect(result.isLoaded, isTrue);
      expect(result.didTimeout, isFalse);
    });

    test('should load a real font', () async {
      var result = await new FontFaceObserver('test1').load(_FontUrls.Roboto);
      expect(result.isLoaded, isTrue);
    });

    test('should load a real font using simulated events', () async {
      var ffo = new FontFaceObserver('test2', useSimulatedLoadEvents: true);
      var result = await ffo.load(_FontUrls.Roboto);
      expect(result.isLoaded, isTrue);
      result = await ffo.check();
      expect(result.isLoaded, isTrue);
    });

    test('should track the font keys and groups correctly', () async {
      await new FontFaceObserver('font_keys1').load(_FontUrls.Roboto);
      await new FontFaceObserver('font_keys2').load(_FontUrls.Roboto);
      await new FontFaceObserver('font_keys3', group: 'group_1').load(_FontUrls.Roboto);
      await new FontFaceObserver('font_keys4', group: 'group_2').load(_FontUrls.Roboto);

      // AdobeBlank is always loaded, so expect that too
      var keys = FontFaceObserver.getLoadedFontKeys();
      expect(keys.length, equals(5));
      expect(keys.contains('font_keys1_normal_normal_normal'), isTrue);
      expect(keys.contains('font_keys2_normal_normal_normal'), isTrue);
      expect(keys.contains('font_keys3_normal_normal_normal'), isTrue);
      expect(keys.contains('font_keys4_normal_normal_normal'), isTrue);
      expect(keys.contains(AdobeBlankKey), isTrue);

      // expect the default group too
      var groups = FontFaceObserver.getLoadedGroups();
      expect(groups.length, equals(4));
      expect(groups.contains(FontFaceObserver.defaultGroup), isTrue);
      expect(groups.contains('group_1'), isTrue);
      expect(groups.contains('group_2'), isTrue);
      expect(groups.contains(AdobeBlankFamily), isTrue);
    });

    test('should not leave temp DOM nodes after detecting', () async {
      var ffo = new FontFaceObserver('no_dom_leaks', useSimulatedLoadEvents: true);
      var result = await ffo.load(_FontUrls.Roboto);
      expect(result.isLoaded, isTrue);
      var elements = querySelectorAll('._ffo_temp');
      if (elements.length > 0) {
        elements.forEach( (el) => print('${el.tagName}.${el.className}'));
      }
      expect(elements.length, isZero);
    });

    test('should unload a font by key', () async {
      var ffo = new FontFaceObserver('unload_by_key');
      String key = ffo.key;
      var result = await ffo.load(_FontUrls.Roboto);
      expect(result.isLoaded, isTrue);
      await FontFaceObserver.unload(key);
      var styleElement = querySelector('style[data-key="${key}"]');
      expect(styleElement,isNull);
    });

    test('should use the default group if no group specified', () async {
      var ffo = new FontFaceObserver('default_group1');
      expect(ffo.group, equals(FontFaceObserver.defaultGroup));
    });

    test('should throw if group is null or whitespace', () async {
      var ffo = new FontFaceObserver('default_group2');
      expect(() => ffo.group = null, throws);
      expect(() => ffo.group = '   ', throws);
    });

    test('should update group in the loaded font map when updating group on an ffo instance', () async {
      var ffo = new FontFaceObserver('update_group', group:'initial_group');
      await ffo.load(_FontUrls.Roboto);
      String newGroup = 'new group';
      ffo.group = newGroup;
      int num = await FontFaceObserver.unloadGroup(newGroup);
      expect(num, equals(1));
    });

    test('should unload a font by group', () async {
      var group = 'somegroup';
      await new FontFaceObserver('unload_by_group1', group: group).load(_FontUrls.Roboto);
      await new FontFaceObserver('unload_by_group2', group: group).load(_FontUrls.Roboto);
      await FontFaceObserver.unloadGroup(group);
      expect(querySelectorAll('style[data-group="${group}"]').length, isZero);
    });


    test('should keep data-uses attribute up to date', () async {
      var ffo = new FontFaceObserver('uses_test');
      String key = ffo.key;
      var result = await ffo.load(_FontUrls.Roboto);
      expect(result.isLoaded, isTrue);
      var styleElement = querySelector('style[data-key="${key}"]');
      expect(styleElement.dataset['uses'],'1');

      // load it again, uses should be 2
      result = await ffo.load(_FontUrls.Roboto);
      expect(result.isLoaded, isTrue);
      expect(styleElement.dataset['uses'],'2');

      // unload it once
      expect(await FontFaceObserver.unload(key), isTrue);
      expect(styleElement.dataset['uses'],'1');

      // unload it again
      expect(await FontFaceObserver.unload(key), isTrue);
      expect(querySelector('style[data-key="${key}"]'), isNull);
      expect(styleElement.dataset['uses'],'0');

      // unload it again, should not go negative
      expect(await FontFaceObserver.unload(key), isFalse);
      expect(querySelector('style[data-key="${key}"]'), isNull);
      expect(querySelector('span[data-key="${key}"]'), isNull);
      expect(styleElement.dataset['uses'],'0');
    });

    test('should timeout on an empty font, not throw an exception', () async {
      var result = await new FontFaceObserver('empty1', timeout: 100).load(_FontUrls.Empty);
      expect(result.isLoaded, isFalse);
      expect(result.didTimeout, isTrue);
    });

    test('should detect an empty font, not throw an exception with simulated events', () async {
      var result = await new FontFaceObserver('empty2', timeout: 100, useSimulatedLoadEvents: true).load(_FontUrls.Empty);
      expect(result.isLoaded, isTrue);
      expect(result.didTimeout, isFalse);
    });

    test('should load user-region-only font', () async {
      var result = await new FontFaceObserver('w', timeout: 100, testString: '\uE0FF').load(_FontUrls.W); // 57599
      expect(result.isLoaded, isTrue);
      expect(result.didTimeout, isFalse);
    });

    test('should find the font if it is already loaded', () async {
      await new FontFaceObserver('test3').load(_FontUrls.Roboto);
      var result = await new FontFaceObserver('test3').check();
      expect(result.isLoaded, isTrue);
    });

    test('should cleanup when not successful', () async {
      var ffo1 = new FontFaceObserver('cleanup1', timeout: 100, group: 'group1');
      var ffo2 = new FontFaceObserver('cleanup2', timeout: 100, group: 'group2');

      var result1 = await ffo1.load(_FontUrls.Empty);
      var result2 = await ffo2.load(_FontUrls.FontNotFound);
    
      expect(result1.isLoaded, isFalse);
      expect(result2.isLoaded, isFalse);
      expectKeyNotLoaded(ffo1.key);
      expectKeyNotLoaded(ffo2.key);
      expectGroupNotLoaded(ffo1.group);
      expectGroupNotLoaded(ffo2.group);
    });

    test('should handle async interleaved load and unload calls', () async {
      var ffo1 = new FontFaceObserver('complex1', group: 'group1');
      var ffo2 = new FontFaceObserver('complex2', group: 'group2');
      var ffo3 = new FontFaceObserver('complex3', group: 'group1');
      
      // fire this off async
      var f1 = ffo1.load(_FontUrls.Roboto);
      await FontFaceObserver.unload('group1');
      await f1;
      expectKeyNotLoaded(ffo1.key);
      expectGroupNotLoaded(ffo1.group);
      /*
      construct 3 different FFOs, same key, different group
      make load take 1 second
      call load on FFO1
      call load on FFO2
      wait 200ms
      call await unload group 1
      it should wait until load finishes, then decrement uses for group 1
      unload group 2 and it should be removed from the DOM and from the internal map
      */
      // fail intentionally until the test is written
      expect(1, equals(false));
    });

    test('should handle spaces and numbers in font family', () async {
      var result = await new FontFaceObserver('Garamond 7').load(_FontUrls.Roboto);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range within ASCII', () async {
      var result = await new FontFaceObserver('unicode1', testString: '\u0021').load(_FontUrls.Subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside ASCII (but within BMP)', () async {
      var result = await new FontFaceObserver('unicode2', testString: '\u4e2d\u56fd').load(_FontUrls.Subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside the BMP', () async {
      var result = await new FontFaceObserver('unicode3', testString: '\udbff\udfff').load(_FontUrls.Subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range within ASCII with simulated events', () async {
      var result = await new FontFaceObserver('unicode1', testString: '\u0021', useSimulatedLoadEvents: true).load(_FontUrls.Subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside ASCII (but within BMP) with simulated events', () async {
      var result = await new FontFaceObserver('unicode2', testString: '\u4e2d\u56fd', useSimulatedLoadEvents: true).load(_FontUrls.Subset);
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside the BMP with simulated events', () async {
      var result = await new FontFaceObserver('unicode3', testString: '\udbff\udfff', useSimulatedLoadEvents: true).load(_FontUrls.Subset);
      expect(result.isLoaded, isTrue);
    });
  });
}
