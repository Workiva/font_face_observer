import 'dart:html';
import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:font_face_observer/font_face_observer.dart';
import 'package:font_face_observer/data_uri.dart';

@TestOn('browser')
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
      var loaded = await new FontFaceObserver('bogus', timeout: 100).load('/bogus.ttf');
      expect(loaded, isFalse);
    });

    test('should timeout and fail for a bogus font with simulated events', () async {
      var loaded = await new FontFaceObserver('bogus2', timeout: 100, useSimulatedLoadEvents: true).load('/bogus.ttf');
      expect(loaded, isFalse);
    });

    test('should load a real font', () async {
      var loaded = await new FontFaceObserver('test1').load('Garamond.ttf');
      expect(loaded, isTrue);
    });

    test('should load a real font using simulated events', () async {
      var ffo = new FontFaceObserver('test2', useSimulatedLoadEvents: true);
      var loaded = await ffo.load('Garamond.ttf');
      expect(loaded, isTrue);
      loaded = false;
      loaded = await ffo.isLoaded();
      expect(loaded, isTrue);
    });

    test('should find the font if it is already loaded', () async {
      await new FontFaceObserver('test3').load('Garamond.ttf');
      var loaded = await new FontFaceObserver('test3').isLoaded();
      expect(loaded, isTrue);
    });

    test('should handle spaces and numbers in font family', () async {
      var loaded = await new FontFaceObserver('Ga ramond_-77').load('Garamond.ttf');
      expect(loaded, isTrue);
    });

    // test('should handle RTL documents', () async {});

    test('should find a font with a custom unicode range within ASCII', () async {
      var loaded = await new FontFaceObserver('unicode1', testString: '\u0021').load('subset.ttf');
      expect(loaded, isTrue);
    });

    test('should find a font with a custom unicode range outside ASCII (but within BMP)', () async {
      var loaded = await new FontFaceObserver('unicode2', testString: '\u4e2d\u56fd').load('subset.ttf');
      expect(loaded, isTrue);
    });

    test('should find a font with a custom unicode range outside the BMP', () async {
      var loaded = await new FontFaceObserver('unicode3', testString: '\udbff\udfff').load('subset.ttf');
      expect(loaded, isTrue);
    });

    test('should find a font with a custom unicode range within ASCII with simulated events', () async {
      var loaded = await new FontFaceObserver('unicode1', testString: '\u0021', useSimulatedLoadEvents: true).load('subset.ttf');
      expect(loaded, isTrue);
    });

    test('should find a font with a custom unicode range outside ASCII (but within BMP) with simulated events', () async {
      var loaded = await new FontFaceObserver('unicode2', testString: '\u4e2d\u56fd', useSimulatedLoadEvents: true).load('subset.ttf');
      expect(loaded, isTrue);
    });

    test('should find a font with a custom unicode range outside the BMP with simulated events', () async {
      var loaded = await new FontFaceObserver('unicode3', testString: '\udbff\udfff', useSimulatedLoadEvents: true).load('subset.ttf');
      expect(loaded, isTrue);
    });

    // These tests pass but cause coverage to break due to CORS request to a file URL
    // so they are commented out for now :(

    // test('should load and detect a base64 data URL font successfully', () async {
    //   ByteBuffer buf = (await HttpRequest.request('Garamond.ttf', responseType: 'arraybuffer')).response;
    //   String dataUrl = new DataUri(data: DataUri.base64EncodeByteBuffer(buf)).toString();
    //   var loaded = await new FontFaceObserver('base64font').load(dataUrl);
    //   expect(loaded, isTrue);
    // });

    // test('should load and detect a base64 data URL font successfully with simulated events', () async {
    //   ByteBuffer buf = (await HttpRequest.request('Garamond.ttf', responseType: 'arraybuffer')).response;
    //   String dataUrl = new DataUri(data: DataUri.base64EncodeByteBuffer(buf)).toString();
    //   var loaded = await new FontFaceObserver('base64font', useSimulatedLoadEvents: true).load(dataUrl);
    //   expect(loaded, isTrue);
    // });

    // test('should load and detect a object URL font successfully', () async {
    //   HttpRequest req = await HttpRequest.request('Garamond.ttf', responseType: 'blob');
    //   Blob blob = req.response;
    //   String blobUrl = Url.createObjectUrl(blob);
    //   var loaded = await new FontFaceObserver('blobfont').load(blobUrl);
    //   Url.revokeObjectUrl(blobUrl);
    //   expect(loaded, isTrue);
    // });
  });
}
