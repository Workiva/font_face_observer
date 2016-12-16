@TestOn('browser')
import 'package:test/test.dart';
import 'package:font_face_observer/font_face_observer.dart';

class _FontUrls {
  static const String Roboto = 'fonts/Roboto.ttf';
  static const String W = 'fonts/W.ttf';
  static const String Empty = 'fonts/empty.ttf';
  static const String Subset = 'fonts/subset.ttf';
  static const String FontNotFound = 'fonts/font_not_found.ttf';
}

main() {
  group('FontFaceObserver', () {
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

    test('should handle spaces and numbers in font family', () async {
      var result = await new FontFaceObserver('Ga ramond_-77').load(_FontUrls.Roboto);
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
