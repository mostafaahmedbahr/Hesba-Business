import 'package:intl/intl.dart';

extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension DateTimeExtensions on DateTime {
  String get formattedDate => DateFormat('yyyy-MM-dd').format(this);
  String get formattedTime => DateFormat('HH:mm').format(this);
  String get formattedDateTime => DateFormat('yyyy-MM-dd HH:mm').format(this);
  String get formattedDayName => DateFormat('EEEE', 'ar').format(this);
  String get formattedMonthName => DateFormat('MMMM', 'ar').format(this);
}

extension DoubleExtensions on double {
  String get toCurrency => '${toStringAsFixed(2)} ج.م';
  String get toFixed2 => toStringAsFixed(2);
}
