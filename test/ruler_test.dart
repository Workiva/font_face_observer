@TestOn('browser')
import 'dart:html';
import 'dart:async';
import 'package:test/test.dart';
import 'package:font_face_observer/src/ruler.dart';

const int _startWidth = 100;

void main() {
  Ruler ruler;

  setUp(() {
    ruler = new Ruler('hello');
    ruler.setFont('');
    ruler.setWidth(_startWidth);
    document.body.append(ruler.element);
  });

  tearDown(() {
    ruler.element.remove();
    ruler = null;
  });

  Future<Null> testResize(num width1) async {
    Completer<Null> c = new Completer<Null>();
    ruler.onResize((num width) {
      expect(width, equals(width1));
      c.complete();
    });
    ruler.setWidth(width1);
    return c.future;
  }

  Future<Null> testTwoResizes(num width1, num width2) async {
    Completer<Null> c = new Completer<Null>();
    bool first = true;
    ruler.onResize((num width) {
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
      expect(ruler.getWidth(), equals(_startWidth));
    });

    test('should detect expansion', () async {
      return testResize(_startWidth + 100);
    });

    test('should detect collapse', () async {
      return testResize(_startWidth - 50);
    });

    test('should not detect a set to the same width', () async {
      bool failed = false;
      ruler.onResize((num width) {
        failed = true;
      });
      ruler.setWidth(_startWidth);
      Completer<Null> c = new Completer<Null>();
      new Timer(new Duration(milliseconds: 20), () {
        expect(failed, isFalse);
        expect(ruler.getWidth(), equals(_startWidth));
        c.complete();
      });
      return c.future;
    });

    test('should detect multiple expansions', () async {
      return testTwoResizes(_startWidth + 100, _startWidth + 200);
    });

    test('should detect multiple collapses', () async {
      return testTwoResizes(_startWidth - 30, _startWidth - 50);
    });

    test('should detect an expansion and a collapse', () async {
      return testTwoResizes(_startWidth + 100, _startWidth);
    });

    test('should detect a collapse and an expansion', () async {
      return testTwoResizes(_startWidth - 30, _startWidth);
    });

    test('should detect single pixel collapses', () async {
      return testTwoResizes(_startWidth - 1, _startWidth - 2);
    });

    test('should detect single pixel expansions', () async {
      return testTwoResizes(_startWidth + 1, _startWidth + 2);
    });
  });
}
