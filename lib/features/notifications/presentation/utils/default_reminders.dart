import 'package:easy_localization/easy_localization.dart';

import '../../../../core/models/local_reminder.dart';

/// The 4 built-in public daily reminders that EVERY user receives.
///
/// They live in the public namespace (ids 1004..1007, reserved in the model),
/// are re-seeded/synced on every launch and can NEVER be edited, deleted or
/// paused by the client. They are fully independent of personal reminders.
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