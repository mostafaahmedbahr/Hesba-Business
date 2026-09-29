import 'package:easy_localization/easy_localization.dart';

import 'local_reminder.dart';

/// الـ 4 تذكيرات اليومية الثابتة (أول تشغيل بس).
List<LocalReminder> buildDefaultReminders() {
  return [
    LocalReminder(
      id: 1004,
      title: 'defaultN1Title'.tr(),
      body: 'defaultN1Body'.tr(),
      hour: 10,
      minute: 0,
      isBuiltIn: true,
    ),
    LocalReminder(
      id: 1005,
      title: 'defaultN2Title'.tr(),
      body: 'defaultN2Body'.tr(),
      hour: 13,
      minute: 0,
      isBuiltIn: true,
    ),
    LocalReminder(
      id: 1006,
      title: 'defaultN3Title'.tr(),
      body: 'defaultN3Body'.tr(),
      hour: 17,
      minute: 0,
      isBuiltIn: true,
    ),
    LocalReminder(
      id: 1007,
      title: 'defaultN4Title'.tr(),
      body: 'defaultN4Body'.tr(),
      hour: 22,
      minute: 0,
      isBuiltIn: true,
    ),
  ];
}
