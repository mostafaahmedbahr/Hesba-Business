import 'package:flutter/material.dart';

import 'app_routes.dart';

const _activityPrefix = 'activity:';

/// يفتح الشاشة المناسبة لـ payload إشعار.
///
/// الأشكال المتوقعة:
/// - `activity:sale`    → الداشبورد على تاب المبيعات
/// - `activity:product` → الداشبورد على تاب المنتجات
/// - `activity:return`  → شاشة المرتجعات
/// - `activity:expense` → شاشة المصروفات
/// - `reminder` / `test`→ شاشة الإشعارات (التذكيرات)
/// - أي حاجة تانية (FCM عام) → الداشبورد
///
/// [clearStack] = true للضغط على إشعار من شريط الإشعارات (نبدأ من أول الشاشة)،
/// و false للضغط جوه التطبيق (نرجّع الـ back يشتغل).
void openNotificationPayload(
  NavigatorState navigator,
  String? payload, {
  bool clearStack = true,
}) {
  final raw = payload ?? '';
  final kind =
      raw.startsWith(_activityPrefix) ? raw.substring(_activityPrefix.length) : raw;

  void go(String route, {Object? arguments}) {
    if (clearStack) {
      navigator.pushNamedAndRemoveUntil(
        route,
        (r) => false,
        arguments: arguments,
      );
    } else {
      navigator.pushNamed(route, arguments: arguments);
    }
  }

  void goDashboard([int? tab]) {
    go(
      AppRoutes.dashboard,
      arguments:
          tab == null ? null : <String, dynamic>{'initialTab': tab},
    );
  }

  switch (kind) {
    case 'sale': // تاب المبيعات.
      goDashboard(2);
      break;
    case 'product': // تاب المنتجات.
      goDashboard(1);
      break;
    case 'return':
      go(AppRoutes.returnsView);
      break;
    case 'expense':
      go(AppRoutes.expensesView);
      break;
    case 'reminder':
    case 'test':
      go(AppRoutes.notifications);
      break;
    default:
      goDashboard();
  }
}
