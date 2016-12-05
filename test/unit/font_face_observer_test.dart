@TestOn('browser')

import 'dart:html';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:font_face_observer/font_face_observer.dart';
import 'package:font_face_observer/data_uri.dart';

main() {
  group('FontFaceObserver', () {
    test('should init correctly with defaults', () {
      var ffo = new FontFaceObserver('my family');
      expect(ffo, isNotNull);
      expect(ffo.style, equals('normal'));
      expect(ffo.weight, equals('normal'));
      expect(ffo.stretch, equals('normal'));
      expect(ffo.testString, equals('BESbswy'));
      expect(ffo.timeout, equals(3000));
      expect(ffo.useSimulatedLoadEvents, equals(false));
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
    });
    
    test('should timeout and fail for a bogus font', () async {
      var result = await new FontFaceObserver('bogus', timeout: 100).load('/bogus.ttf');
      expect(result.isLoaded, isFalse);
      expect(result.didTimeout, isTrue);
    });

    test('should timeout and fail for a bogus font with simulated events', () async {
      var result = await new FontFaceObserver('bogus2', timeout: 100, useSimulatedLoadEvents: true).load('/bogus.ttf');
      expect(result.isLoaded, isFalse);
      expect(result.didTimeout, isTrue);
    });

    test('should load a real font', () async {
      var result = await new FontFaceObserver('test1').load('Garamond.ttf');
      expect(result.isLoaded, isTrue);
    });

    test('should load a real font using simulated events', () async {
      var ffo = new FontFaceObserver('test2', useSimulatedLoadEvents: true);
      var result = await ffo.load('Garamond.ttf');
      expect(result.isLoaded, isTrue);
      result = await ffo.isLoaded();
      expect(result.isLoaded, isTrue);
    });

    test('should find the font if it is already loaded', () async {
      await new FontFaceObserver('test3').load('Garamond.ttf');
      var result = await new FontFaceObserver('test3').isLoaded();
      expect(result.isLoaded, isTrue);
    });

    test('should handle spaces and numbers in font family', () async {
      var result = await new FontFaceObserver('Ga ramond_-77').load('Garamond.ttf');
      expect(result.isLoaded, isTrue);
    });

    // test('should handle RTL documents', () async {});

    test('should find a font with a custom unicode range within ASCII', () async {
      var result = await new FontFaceObserver('unicode1', testString: '\u0021').load('subset.ttf');
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside ASCII (but within BMP)', () async {
      var result = await new FontFaceObserver('unicode2', testString: '\u4e2d\u56fd').load('subset.ttf');
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside the BMP', () async {
      var result = await new FontFaceObserver('unicode3', testString: '\udbff\udfff').load('subset.ttf');
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range within ASCII with simulated events', () async {
      var result = await new FontFaceObserver('unicode1', testString: '\u0021', useSimulatedLoadEvents: true).load('subset.ttf');
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside ASCII (but within BMP) with simulated events', () async {
      var result = await new FontFaceObserver('unicode2', testString: '\u4e2d\u56fd', useSimulatedLoadEvents: true).load('subset.ttf');
      expect(result.isLoaded, isTrue);
    });

    test('should find a font with a custom unicode range outside the BMP with simulated events', () async {
      var result = await new FontFaceObserver('unicode3', testString: '\udbff\udfff', useSimulatedLoadEvents: true).load('subset.ttf');
      expect(result.isLoaded, isTrue);
    });
  });
}
