/// Central parsing for money / quantity / discount fields.
///
/// Arabic-Indic (٠١٢٣٤٥٦٧٨٩) and Persian (۰۱۲۳۴۵۶۷۸۹) digits are converted to
/// Latin first: bare `double.tryParse` reads them as `null`, which silently
/// zeroes totals when the user types on an Arabic keyboard.
class NumberParser {
  NumberParser._();

  static const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  static const _persian = '۰۱۲۳۴۵۶۷۸۹';

  /// `١٢٣.٥` → `123.5` (also trims and normalises Arabic decimal separators).
  static String toLatin(String input) {
    final buffer = StringBuffer();
    for (final unit in input.trim().runes) {
      final char = String.fromCharCode(unit);
      final arabicIndex = _arabicIndic.indexOf(char);
      if (arabicIndex != -1) {
        buffer.write(arabicIndex);
        continue;
      }
      final persianIndex = _persian.indexOf(char);
      if (persianIndex != -1) {
        buffer.write(persianIndex);
        continue;
      }
      // Arabic decimal separator (٫) and thousands separator (٬).
      if (char == '٫') {
        buffer.write('.');
        continue;
      }
      if (char == '٬' || char == ' ') continue;
      buffer.write(char);
    }
    return buffer.toString();
  }

  /// Parses a money/quantity field; invalid input becomes `0`.
  static double parseDouble(String? value) {
    return double.tryParse(toLatin(value ?? '')) ?? 0;
  }

  /// Parses an integer field (e.g. stock); invalid input becomes `0`.
  static int parseInt(String? value) {
    return int.tryParse(toLatin(value ?? '')) ?? 0;
  }
}
