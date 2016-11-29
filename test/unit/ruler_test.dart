import 'dart:html';
import 'package:test/test.dart';
import 'package:font_face_observer/ruler.dart';

const int START_WIDTH = 100;

@TestOn('browser')
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

  testTwoResizes(width1, width2) async {
    var first = true;
    ruler.onResize( (width) {
      if (first) {
        expect(width, equals(width1));
        first = false;
        ruler.setWidth(width2);
      } else {
        expect(width, equals(width2));
      }
    });
    ruler.setWidth(width1);
  }

  group('Ruler', () {
    test('constructor should init correctly', () {
      expect(ruler, isNotNull);
      expect(ruler.element, isNotNull);
      expect(ruler.getWidth(), equals(START_WIDTH));
    });
    
    test('should detect expansion', () async {
      var new_width = 200;
      ruler.onResize((width) {
        expect(width, equals(new_width));
      });
      ruler.setWidth(new_width);
    });

    test('should detect collapse', () async {
      var new_width = 50;
      ruler.onResize((width) {
        expect(width, equals(new_width));
      });
      ruler.setWidth(new_width);
    });

    test('should detect multiple expansions', () async {
      testTwoResizes(START_WIDTH + 100, START_WIDTH + 200);
    });
    
    test('should detect multiple collapses', () async {
      testTwoResizes(START_WIDTH - 30, START_WIDTH - 50);
    });

    test('should detect an expansion and a collapse', () async {
      testTwoResizes(START_WIDTH + 100, START_WIDTH);
    });

    test('should detect a collapse and an expansion', () async {
      testTwoResizes(START_WIDTH - 30, START_WIDTH);
    });
    
    test('should detect single pixel collapses', () async {
      testTwoResizes(START_WIDTH - 1, START_WIDTH - 2);
    });

    test('should detect single pixel expansions', () async {
      testTwoResizes(START_WIDTH + 1, START_WIDTH + 2);
    });

  });
}