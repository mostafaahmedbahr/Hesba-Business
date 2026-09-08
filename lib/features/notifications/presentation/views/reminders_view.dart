import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/local_reminder.dart';
import '../../data/repos/notification_repo.dart';
import '../cubit/notification_cubit.dart';
import '../states/notification_state.dart';

const _brandTop = Color(0xFF1A4FD6);
const _brandMid = Color(0xFF3B6FF5);
const _brandBottom = Color(0xFF7C4DFF);

const _headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_brandTop, _brandMid, _brandBottom],
);

class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        elevation: 6,
        backgroundColor: _brandTop,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'remindersAddButton'.tr(),
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocProvider(
        create: (_) => NotificationCubit(repo: sl<NotificationRepo>())
          ..loadReminders(),
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            // Personal reminders (full control) only. The public daily
            // reminders are hidden from the UI but stay scheduled/synced
            // independently by the cubit at startup.
            return CustomScrollView(
              slivers: [
                _buildHeader(context, state.personalReminders.length),
                if (state.personalReminders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 110.h),
                    sliver: SliverList.separated(
                      itemCount: state.personalReminders.length,
                      separatorBuilder: (_, _) => SizedBox(height: 14.h),
                      itemBuilder: (context, index) {
                        final r = state.personalReminders[index];
                        return _ReminderCard(
                          reminder: r,
                          onToggle: () => context
                              .read<NotificationCubit>()
                              .toggleReminderEnabled(r),
                          onEdit: () => _openForm(context, reminder: r),
                          onDelete: () => _confirmDelete(context, r),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 128.h,
      backgroundColor: _brandTop,
      foregroundColor: Colors.white,
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: _headerGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 44.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'remindersTitle'.tr(),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'remindersCount'.tr(args: ['$count']),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'remindersHeaderSubtitle'.tr(),
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104.w,
              height: 104.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _brandTop.withValues(alpha: 0.12),
                    _brandBottom.withValues(alpha: 0.12),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 52.sp,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'remindersEmpty'.tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'remindersEmptyHint'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5.sp,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),
            FilledButton.icon(
              onPressed: () => _openForm(context),
              style: FilledButton.styleFrom(
                backgroundColor: _brandTop,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'remindersAddButton'.tr(),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    LocalReminder? reminder,
  }) async {
    final cubit = context.read<NotificationCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (_) => _ReminderFormSheet(cubit: cubit, reminder: reminder),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LocalReminder reminder,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text('reminderDeleteConfirmTitle'.tr()),
        content: Text('reminderDeleteConfirmBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('reminderDelete'.tr()),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<NotificationCubit>().deleteReminder(reminder.id);
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final LocalReminder reminder;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ReminderCard({
    required this.reminder,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = reminder.enabled;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimeBadge(reminder: reminder),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminder.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (onToggle != null)
                        Switch(
                          value: enabled,
                          onChanged: (_) => onToggle!(),
                          activeTrackColor: _brandTop,
                          thumbColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? Colors.white
                                : theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    reminder.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      _Pill(
                        icon: Icons.update_rounded,
                        label: _repeatLabel(context, reminder),
                      ),
                      const Spacer(),
                      if (onEdit != null)
                        _IconAction(
                          icon: Icons.edit_rounded,
                          color: theme.colorScheme.primary,
                          onTap: onEdit!,
                        ),
                      SizedBox(width: 6.w),
                      if (onDelete != null)
                        _IconAction(
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFE53935),
                          onTap: onDelete!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final LocalReminder reminder;

  const _TimeBadge({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final hour = reminder.hour;
    final minute = reminder.minute;
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final isAm = hour < 12;

    return Container(
      width: 58.w,
      height: 58.w,
      decoration: BoxDecoration(
        gradient: !reminder.enabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.withValues(alpha: 0.35),
                  Colors.grey.withValues(alpha: 0.25),
                ],
              )
            : _headerGradient,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: reminder.enabled
            ? [
                BoxShadow(
                  color: _brandTop.withValues(alpha: 0.35),
                  blurRadius: 12.r,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$h12:${minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            isAm ? 'AM' : 'PM',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: theme.colorScheme.primary),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(9.w),
          child: Icon(icon, size: 18.sp, color: color),
        ),
      ),
    );
  }
}

class _ReminderFormSheet extends StatefulWidget {
  final NotificationCubit cubit;
  final LocalReminder? reminder;

  const _ReminderFormSheet({required this.cubit, this.reminder});

  @override
  State<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<_ReminderFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late int _hour;
  late int _minute;
  late ReminderRepeat _repeat;
  late int _weekday;
  bool _saving = false;

  bool get _isEdit => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.reminder;
    _titleController = TextEditingController(text: existing?.title);
    _bodyController = TextEditingController(text: existing?.body);
    _hour = existing?.hour ?? 10;
    _minute = existing?.minute ?? 0;
    _repeat = existing?.repeat ?? ReminderRepeat.daily;
    _weekday = existing?.weekday ?? DateTime.now().weekday;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: _brandTop,
              ),
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

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    if (_isEdit) {
      await widget.cubit.updateReminder(
        widget.reminder!.copyWith(
          title: _titleController.text,
          body: _bodyController.text,
          hour: _hour,
          minute: _minute,
          repeat: _repeat,
          weekday: _repeat == ReminderRepeat.weekly ? _weekday : null,
        ),
      );
    } else {
      await widget.cubit.addReminder(
        title: _titleController.text,
        body: _bodyController.text,
        hour: _hour,
        minute: _minute,
        repeat: _repeat,
        weekday: _repeat == ReminderRepeat.weekly ? _weekday : null,
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    gradient: _headerGradient,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    _isEdit ? Icons.edit_rounded : Icons.add_alert_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  _isEdit
                      ? 'reminderFormEdit'.tr()
                      : 'reminderFormAdd'.tr(),
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'reminderFormTitleField'.tr(),
                prefixIcon: const Icon(Icons.title_rounded),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(
                    color: _brandTop,
                    width: 1.6,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'reminderFormBodyField'.tr(),
                prefixIcon: const Icon(Icons.notes_rounded),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(
                    color: _brandTop,
                    width: 1.6,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            _buildTimeRow(context),
            SizedBox(height: 14.h),
            _buildRepeatSection(context),
            if (_repeat == ReminderRepeat.weekly) ...[
              SizedBox(height: 14.h),
              _buildWeekdayRow(context),
            ],
            SizedBox(height: 22.h),
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandTop,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEdit
                            ? 'reminderFormUpdate'.tr()
                            : 'reminderFormSave'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 22.sp),
              SizedBox(width: 12.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(
                Icons.chevron_right_rounded,
                size: 18.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context) {
    return _buildValueRow(
      icon: Icons.access_time_rounded,
      label: 'reminderFormTime'.tr(),
      value: _timeLabel(context, _hour, _minute),
      onTap: _pickTime,
    );
  }

  Widget _buildRepeatSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'reminderFormRepeat'.tr(),
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            _RepeatChoice(
              icon: Icons.event_repeat_rounded,
              label: 'repeatDaily'.tr(),
              selected: _repeat == ReminderRepeat.daily,
              onTap: () => setState(() => _repeat = ReminderRepeat.daily),
            ),
            SizedBox(width: 12.w),
            _RepeatChoice(
              icon: Icons.repeat_rounded,
              label: 'repeatWeekly'.tr(),
              selected: _repeat == ReminderRepeat.weekly,
              onTap: () => setState(() => _repeat = ReminderRepeat.weekly),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayRow(BuildContext context) {
    return _buildValueRow(
      icon: Icons.calendar_today_rounded,
      label: 'reminderFormWeekday'.tr(),
      value: _weekdayLabel(context, _weekday),
      onTap: () => _pickWeekday(context),
    );
  }

  Future<void> _pickWeekday(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          children: [
            Center(
              child: Container(
                width: 44.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'reminderFormWeekday'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            for (var day = 1; day <= 7; day++)
              ListTile(
                leading: Icon(
                  _dayIcon(_weekdayLabel(context, day)),
                  color: Theme.of(sheetContext).colorScheme.primary,
                ),
                title: Text(
                  _weekdayLabel(context, day),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight:
                        day == _weekday ? FontWeight.w800 : FontWeight.w500,
                    color: day == _weekday
                        ? Theme.of(sheetContext).colorScheme.primary
                        : Theme.of(sheetContext).colorScheme.onSurface,
                  ),
                ),
                trailing: day == _weekday
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(sheetContext, day),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() => _weekday = selected);
    }
  }

  IconData _dayIcon(String dayName) {
    if (dayName == 'Friday' || dayName == 'الجمعة') {
      return Icons.card_giftcard_rounded;
    }
    if (dayName == 'Saturday' || dayName == 'السبت') {
      return Icons.celebration_rounded;
    }
    if (dayName == 'Sunday' || dayName == 'الأحد') {
      return Icons.wb_sunny_rounded;
    }
    return Icons.work_outline_rounded;
  }
}

class _RepeatChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RepeatChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 13.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _brandTop
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected
                  ? _brandTop
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17.sp,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 7.w),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _repeatLabel(BuildContext context, LocalReminder r) {
  if (r.repeat == ReminderRepeat.weekly) {
    return '${'repeatWeekly'.tr()} — ${_weekdayLabel(context, r.weekday ?? 1)}';
  }
  return 'repeatDaily'.tr();
}

String _weekdayLabel(BuildContext context, int weekday) {
  final isAr = context.locale.languageCode == 'ar';
  if (isAr) {
    switch (weekday) {
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      default:
        return 'الأحد';
    }
  }
  switch (weekday) {
    case 1:
      return 'Monday';
    case 2:
      return 'Tuesday';
    case 3:
      return 'Wednesday';
    case 4:
      return 'Thursday';
    case 5:
      return 'Friday';
    case 6:
      return 'Saturday';
    default:
      return 'Sunday';
  }
}

String _timeLabel(BuildContext context, int hour, int minute) {
  final isAr = context.locale.languageCode == 'ar';
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final mm = minute.toString().padLeft(2, '0');
  if (!isAr) {
    return '$h12:$mm ${hour >= 12 ? 'PM' : 'AM'}';
  }
  return '$h12:$mm ${hour >= 12 ? 'مساءً' : 'صباحًا'}';
}