@TestOn('browser')
import 'dart:html';
import 'dart:async';
import 'package:test/test.dart';
import 'package:font_face_observer/src/ruler.dart';

const int START_WIDTH = 100;

main() {
  Ruler ruler;

  setUp(() {
    ruler = new Ruler('hello');
    ruler.setFont('');
    ruler.setWidth(START_WIDTH);
    document.body.append(ruler.element);
  });

  tearDown(() {
    ruler.element.remove();
    ruler = null;
  });

  Future testResize(width1) async {
    Completer c = new Completer();
    ruler.onResize((width) {
      expect(width, equals(width1));
      c.complete();
    });
    ruler.setWidth(width1);
    return c.future;
  }

  Future testTwoResizes(width1, width2) async {
    Completer c = new Completer();
    var first = true;
    ruler.onResize((width) {
      if (first) {
        expect(width, equals(width1));
        first = false;
        ruler.setWidth(width2);
      } else {
        expect(width, equals(width2));
        c.complete();
      }
    });
    ruler.setWidth(width1);
    return c.future;
  }

  group('Ruler', () {
    test('constructor should init correctly', () {
      expect(ruler, isNotNull);
      expect(ruler.element, isNotNull);
      expect(ruler.getWidth(), equals(START_WIDTH));
    });

    test('should detect expansion', () async {
      return testResize(START_WIDTH + 100);
    });

    test('should detect collapse', () async {
      return testResize(START_WIDTH - 50);
    });

    test('should not detect a set to the same width', () async {
      bool failed = false;
      ruler.onResize((width) {
        failed = true;
      });
      ruler.setWidth(START_WIDTH);
      Completer c = new Completer();
      new Timer(new Duration(milliseconds: 20), () {
        expect(failed, isFalse);
        expect(ruler.getWidth(), equals(START_WIDTH));
        c.complete();
      });
      return c.future;
    });

    test('should detect multiple expansions', () async {
      return testTwoResizes(START_WIDTH + 100, START_WIDTH + 200);
    });

    test('should detect multiple collapses', () async {
      return testTwoResizes(START_WIDTH - 30, START_WIDTH - 50);
    });

    test('should detect an expansion and a collapse', () async {
      return testTwoResizes(START_WIDTH + 100, START_WIDTH);
    });

    test('should detect a collapse and an expansion', () async {
      return testTwoResizes(START_WIDTH - 30, START_WIDTH);
    });

    test('should detect single pixel collapses', () async {
      return testTwoResizes(START_WIDTH - 1, START_WIDTH - 2);
    });

    test('should detect single pixel expansions', () async {
      return testTwoResizes(START_WIDTH + 1, START_WIDTH + 2);
    });
  });
}
