import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/notification_service.dart';
import 'models/expense_model.dart';

/// جدولة/إلغاء إشعارات التذكير لالتزام مصروف متكرر (daily/weekly/monthly).
///
/// لكل قالب تُجدول الدفعات القادمة كإشعارات أحادية (one-shot) بأمدٍ بعيد
/// (يومي→30، أسبوعي→16، شهري→12). عند كل مزامنة (فتح التطبيق / حفظ /
/// تعديل / حذف) تُلغى كلها وتُعاد من جديد بالكامل — فلا تتكرر الإشعارات
/// ولا تتخلف حتى مع مرّة واحدة توقّف فيها التطبيق لأسابيع.
abstract class ExpenseReminderScheduler {
  const ExpenseReminderScheduler._();

  /// عدد الشُقّاق المحجوزين لكل التزام (حد أقصى للجدولة).
  static const int slotCount = 32;

  /// معرّف إشعار القالب في الشُقّ [slot] — مستقر بين الجلسات،
  /// ولا يتداخل مع نطاقات التذكيرات/الإشعارات/النشاط الأخرى
  /// (1001، 1002، 1004-1007، 2000+، 4000+، 500000+).
  static int reminderId(String expenseId, int slot) {
    var folded = 0;
    for (final code in expenseId.runes) {
      folded = (folded * 131 + code) % 9000;
    }
    return 500000 + folded * 33 + slot;
  }

  /// يلغي كل إشعارات هذا القالب (0..[slotCount]-1).
  static Future<void> cancelAll(String expenseId) async {
    final service = NotificationService();
    for (var slot = 0; slot < slotCount; slot++) {
      await service.cancelNotification(reminderId(expenseId, slot));
    }
  }

  /// يلغي ثم يعيد الجدولة من الموعد القادم فصاعدًا.
  static Future<void> reschedule(ExpenseModel template) async {
    await cancelAll(template.expenseId);
    if (!template.isTemplate) return;
    final dueBase = template.nextDue;
    if (dueBase == null) return;
    var due = dueBase;

    final money = template.amount == template.amount.roundToDouble()
        ? template.amount.toInt().toString()
        : template.amount.toStringAsFixed(2);
    final recurrenceLabel = _recurrenceLabel(template.recurrence);
    final dateFormat = DateFormat('dd/MM • hh:mm a', 'ar');

    for (var slot = 0;
        slot < ExpenseModel.slotCountFor(template.recurrence);
        slot++) {
      final reminderAt = due.subtract(ExpenseModel.offsetFor(template.recurrence));
      // الموعد في الماضي بالفعل (تذكرة فاتت) — لا نُجدول إشعارًا.
      if (reminderAt.isAfter(DateTime.now())) {
        await NotificationService().local.zonedSchedule(
              reminderId(template.expenseId, slot),
              template.title,
              '$money ج.م • $recurrenceLabel • ${dateFormat.format(due)}',
              tz.TZDateTime.from(reminderAt.toUtc(), tz.UTC),
              NotificationService().reminderDetails(),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: 'activity:expense',
            );
      }
      due = ExpenseModel.advanceNextDue(due, template.recurrence);
    }
  }

  static String _recurrenceLabel(String recurrence) => switch (recurrence) {
        ExpenseModel.recurrenceDaily => 'excRecurrenceDailyLabel'.tr(),
        ExpenseModel.recurrenceWeekly => 'excRecurrenceWeeklyLabel'.tr(),
        ExpenseModel.recurrenceMonthly => 'excRecurrenceMonthlyLabel'.tr(),
        _ => '',
      };
}
