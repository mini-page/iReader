import 'package:flutter_test/flutter_test.dart';
import 'package:ireader/shared/utils/text_utils.dart';

void main() {
  group('stripHtml', () {
    test('removes simple HTML tags', () {
      expect(stripHtml('<p>Hello</p>'), 'Hello');
    });

    test('removes nested HTML tags', () {
      expect(stripHtml('<div><p>Hello <b>World</b></p></div>'), 'Hello World');
    });

    test('handles HTML with entities', () {
      expect(stripHtml('<p>Hello&nbsp;World</p>'), 'Hello World');
    });

    test('returns empty string for empty input', () {
      expect(stripHtml(''), '');
    });

    test('returns plain text unchanged', () {
      expect(stripHtml('Hello World'), 'Hello World');
    });

    test('handles null-like empty content', () {
      expect(stripHtml('   '), '');
    });

    test('removes script and style tags', () {
      final result = stripHtml('<script>alert("x")</script><p>Safe</p>');
      expect(result.contains('alert'), isFalse);
      expect(result.contains('Safe'), isTrue);
    });
  });
}
