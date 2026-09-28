import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/models/local_reminder.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../cubit/notification_cubit.dart';

/// شيت إضافة / تعديل تذكير (تصميم جديد).
class ReminderFormSheet extends StatefulWidget {
  final NotificationCubit cubit;
  final LocalReminder? reminder;

  const ReminderFormSheet({super.key, required this.cubit, this.reminder});

  @override
  State<ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<ReminderFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late int _hour;
  late int _minute;
  late ReminderRepeat _repeat;
  late int _weekday;
  bool _saving = false;

  /// وضع تعديل؟
  bool get _isEdit => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _title = TextEditingController(text: r?.title ?? '');
    _body = TextEditingController(text: r?.body ?? '');
    _hour = r?.hour ?? 10;
    _minute = r?.minute ?? 0;
    _repeat = r?.repeat ?? ReminderRepeat.daily;
    _weekday = r?.weekday ?? DateTime.now().weekday;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// يفتح اختيار الوقت.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFF1A4FD6)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  /// يحفظ (إضافة أو تعديل) — يطلب الإذن الأول لو مقفول.
  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _saving) return;
    // لو الإذن مقفول الإشعار عمره ما هيوصلك — اطلبه قبل الحفظ.
    if (!widget.cubit.state.permissionGranted) {
      await widget.cubit.enablePermissions();
      if (!widget.cubit.state.permissionGranted && mounted) {
        AppToast.error(context, 'فعّل إذن الإشعارات من إعدادات الموبايل عشان التذكير يوصلك');
        return;
      }
    }
    setState(() => _saving = true);
    if (_isEdit) {
      await widget.cubit.updateReminder(
        widget.reminder!.copyWith(
          title: _title.text,
          body: _body.text,
          hour: _hour,
          minute: _minute,
          repeat: _repeat,
          weekday: _repeat == ReminderRepeat.weekly ? _weekday : null,
        ),
      );
    } else {
      await widget.cubit.addReminder(
        title: _title.text,
        body: _body.text,
        hour: _hour,
        minute: _minute,
        repeat: _repeat,
        weekday: _repeat == ReminderRepeat.weekly ? _weekday : null,
      );
    }
    if (!mounted) return;
    // يأكدلك إنه هييجي إمتى قبل ما يقفل.
    AppToast.success(context, 'تمام! هيجيلك ${_fireInfo()}');
    Navigator.pop(context);
  }

  /// سطر "هيجيلك إمتى" (النهاردة / بكرة / يوم كذا + الوقت).
  String _fireInfo() {
    final when = _repeat == ReminderRepeat.weekly
        ? 'يوم ${_dayName(_weekday)}'
        : _isToday() ? 'النهاردة' : 'بكرة';
    return '$when ${_timeText()}';
  }

  /// هل الوقت لسه جاي النهاردة؟ (يومي بس).
  bool _isToday() {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, _hour, _minute);
    return target.isAfter(now);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // مقبض السحب.
            Center(
              child: Container(
                width: 44.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            // عنوان الشيت + زرار قفل.
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A4FD6), Color(0xFF7C4DFF)],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A4FD6).withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isEdit ? Icons.edit_rounded : Icons.add_alert_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEdit ? 'reminderFormEdit'.tr() : 'reminderFormAdd'.tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'اختار الوقت والتكرار وهنفكرك',
                        style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.close_rounded, size: 17.sp, color: const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            // اسم التذكير.
            _Label('reminderFormTitleField'.tr()),
            SizedBox(height: 8.h),
            _Field(
              controller: _title,
              hint: 'مثال: مراجعة مبيعات اليوم',
              icon: Icons.title_rounded,
              isDark: isDark,
            ),
            SizedBox(height: 14.h),
            // نص التذكير.
            _Label('reminderFormBodyField'.tr()),
            SizedBox(height: 8.h),
            _Field(
              controller: _body,
              hint: 'اكتب تفاصيل قصيرة...',
              icon: Icons.notes_rounded,
              isDark: isDark,
              maxLines: 2,
            ),
            SizedBox(height: 14.h),
            // الوقت (كارت كبير).
            _Label('reminderFormTime'.tr()),
            SizedBox(height: 8.h),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2A86), Color(0xFF1A4FD6)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A4FD6).withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.access_time_rounded, color: Colors.white, size: 22.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _timeText(),
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'اضغط لتغيير الوقت',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withValues(alpha: 0.80),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'تغيير',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A4FD6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),
            // التكرار (يومي / أسبوعي).
            _Label('reminderFormRepeat'.tr()),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _RepeatBtn(
                    icon: Icons.event_repeat_rounded,
                    label: 'repeatDaily'.tr(),
                    selected: _repeat == ReminderRepeat.daily,
                    onTap: () => setState(() => _repeat = ReminderRepeat.daily),
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _RepeatBtn(
                    icon: Icons.calendar_month_rounded,
                    label: 'repeatWeekly'.tr(),
                    selected: _repeat == ReminderRepeat.weekly,
                    onTap: () => setState(() => _repeat = ReminderRepeat.weekly),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            // أيام الأسبوع (لو أسبوعي).
            if (_repeat == ReminderRepeat.weekly) ...[
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (int d = 1; d <= 7; d++)
                    ChoiceChip(
                      label: Text(
                        _dayName(d),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: _weekday == d ? FontWeight.w800 : FontWeight.w600,
                          color: _weekday == d
                              ? Colors.white
                              : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
                        ),
                      ),
                      selected: _weekday == d,
                      onSelected: (_) => setState(() => _weekday = d),
                      selectedColor: const Color(0xFF1A4FD6),
                      backgroundColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: _weekday == d
                            ? const Color(0xFF1A4FD6)
                            : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                      showCheckmark: false,
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                    ),
                ],
              ),
            ],
            SizedBox(height: 20.h),
            // زرار الحفظ.
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4FD6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: _saving
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _isEdit ? 'reminderFormUpdate'.tr() : 'reminderFormSave'.tr(),
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// نص الوقت الحالي (12h + صباحًا/مساءً).
  String _timeText() {
    final isAr = context.locale.languageCode == 'ar';
    final h12 = _hour % 12 == 0 ? 12 : _hour % 12;
    final mm = _minute.toString().padLeft(2, '0');
    if (!isAr) return '$h12:$mm ${_hour >= 12 ? 'PM' : 'AM'}';
    return '$h12:$mm ${_hour >= 12 ? 'مساءً' : 'صباحًا'}';
  }

  /// اسم اليوم (مختصر).
  String _dayName(int d) {
    final isAr = context.locale.languageCode == 'ar';
    const ar = ['', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
    const en = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return isAr ? ar[d.clamp(1, 7)] : en[d.clamp(1, 7)];
  }
}

/// عنوان حقل صغير.
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }
}

/// حقل إدخال موحد.
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 19.sp, color: const Color(0xFF1A4FD6)),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Color(0xFF1A4FD6), width: 1.6),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      ),
    );
  }
}

/// زرار تكرار (يومي / أسبوعي).
class _RepeatBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _RepeatBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A4FD6)
              : (isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected
                ? const Color(0xFF1A4FD6)
                : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A4FD6).withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17.sp,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
            SizedBox(width: 7.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
