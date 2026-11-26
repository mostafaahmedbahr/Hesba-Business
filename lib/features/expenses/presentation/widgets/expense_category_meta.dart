import 'package:flutter/material.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

/// يوحّد قيمة التصنيف (محفوظة عربياً أو معروضة مترجمة) إلى المفتاح العربي.
String _catKey(String cat) {
  for (final key in const ['إيجار', 'رواتب', 'مرافق', 'مستلزمات', 'أخرى']) {
    if (cat == key || cat == key.tr()) return key;
  }
  return cat;
}

/// لون تصنيف المصروف.
Color expenseCatColor(String cat) {
  switch (_catKey(cat)) {
    case 'إيجار':
      return const Color(0xFF2563EB);
    case 'رواتب':
      return const Color(0xFF7C3AED);
    case 'مرافق':
      return AppTheme.warningAmber;
    case 'مستلزمات':
      return AppTheme.successDark;
    default:
      return AppTheme.danger;
  }
}

/// أيقونة تصنيف المصروف.
IconData expenseCatIcon(String cat) {
  switch (_catKey(cat)) {
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
