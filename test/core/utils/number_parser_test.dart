import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/utils/number_parser.dart';

void main() {
  group('NumberParser.toLatin', () {
    test('converts Arabic-Indic digits', () {
      expect(NumberParser.toLatin('١٢٣.٥'), '123.5');
    });

    test('converts Persian digits', () {
      expect(NumberParser.toLatin('۱۲۳'), '123');
    });

    test('converts the Arabic decimal separator and drops separators', () {
      expect(NumberParser.toLatin('١٬٢٣٤٫٥'), '1234.5');
    });

    test('leaves Latin input untouched apart from trimming', () {
      expect(NumberParser.toLatin('  12.5 '), '12.5');
    });
  });

  group('NumberParser.parseDouble', () {
    test('parses Arabic-keyboard money input instead of zeroing it', () {
      expect(NumberParser.parseDouble('١٢٣.٥'), 123.5);
    });

    test('returns 0 for invalid input', () {
      expect(NumberParser.parseDouble(''), 0);
      expect(NumberParser.parseDouble(null), 0);
      expect(NumberParser.parseDouble('abc'), 0);
    });
  });

  group('NumberParser.parseInt', () {
    test('parses Arabic-keyboard stock input', () {
      expect(NumberParser.parseInt('٥'), 5);
    });

    test('returns 0 for invalid input', () {
      expect(NumberParser.parseInt(''), 0);
      expect(NumberParser.parseInt(null), 0);
    });
  });
}
