import 'package:flutter/material.dart';

/// لون تصنيف المصروف.
Color expenseCatColor(String cat) {
  switch (cat) {
    case 'إيجار':
      return const Color(0xFF2563EB);
    case 'رواتب':
      return const Color(0xFF7C3AED);
    case 'مرافق':
      return const Color(0xFFF59E0B);
    case 'مستلزمات':
      return const Color(0xFF059669);
    default:
      return const Color(0xFFE11D48);
  }
}

/// أيقونة تصنيف المصروف.
IconData expenseCatIcon(String cat) {
  switch (cat) {
    case 'إيجار':
      return Icons.home_rounded;
    case 'رواتب':
      return Icons.payments_rounded;
    case 'مرافق':
      return Icons.bolt_rounded;
    case 'مستلزمات':
      return Icons.shopping_bag_rounded;
    default:
      return Icons.receipt_long_rounded;
  }
}
