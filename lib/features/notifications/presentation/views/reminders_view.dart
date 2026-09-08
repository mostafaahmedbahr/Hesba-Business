import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/local_reminder.dart';
import '../../data/repos/notification_repo.dart';
import '../cubit/notification_cubit.dart';
import '../states/notification_state.dart';

class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('remindersTitle'.tr()),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        backgroundColor: const Color(0xFF1A4FD6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: BlocProvider(
        create: (_) => NotificationCubit(repo: sl<NotificationRepo>())
          ..loadReminders(),
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state.reminders.isEmpty) {
              return _buildEmptyState(context);
            }

            final builtIns =
                state.reminders.where((r) => r.isBuiltIn).toList();
            final custom = state.reminders.where((r) => !r.isBuiltIn).toList();

            final items = <Widget>[];
            if (builtIns.isNotEmpty) {
              items.add(_sectionHeader(context, 'remindersBuiltInTitle'.tr()));
              items.addAll(
                builtIns.map((r) => _ReminderCard(reminder: r, locked: true)),
              );
            }
            if (custom.isNotEmpty) {
              items.add(_sectionHeader(context, 'remindersCustomTitle'.tr()));
              items.addAll(
                custom.map(
                  (r) => _ReminderCard(
                    reminder: r,
                    onToggle: () => context
                        .read<NotificationCubit>()
                        .toggleReminderEnabled(r),
                    onEdit: () => _openForm(context, reminder: r),
                    onDelete: () => _confirmDelete(context, r),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, index) => items[index],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 12.h),
          Text(
            'remindersEmpty'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'remindersEmptyHint'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
        title: Text('reminderDeleteConfirmTitle'.tr()),
        content: Text('reminderDeleteConfirmBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
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
  final bool locked;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ReminderCard({
    required this.reminder,
    this.locked = false,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 14.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A4FD6), Color(0xFF7C4DFF)],
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Text(
              _compactTime(reminder.hour, reminder.minute),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12.w),
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
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (locked)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 12.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'remindersLocked'.tr(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      if (onToggle != null)
                        Switch(
                          value: reminder.enabled,
                          onChanged: (_) => onToggle!(),
                        ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  reminder.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                if (!locked) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          foregroundColor: theme.colorScheme.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(
                          'edit'.tr(),
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          foregroundColor: const Color(0xFFE53935),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: Text(
                          'reminderDelete'.tr(),
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
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
  bool _saving = false;

  bool get _isEdit => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder?.title);
    _bodyController = TextEditingController(text: widget.reminder?.body);
    _hour = widget.reminder?.hour ?? 10;
    _minute = widget.reminder?.minute ?? 0;
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
        ),
      );
    } else {
      await widget.cubit.addReminder(
        title: _titleController.text,
        body: _bodyController.text,
        hour: _hour,
        minute: _minute,
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
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
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
            SizedBox(height: 16.h),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'reminderFormTitleField'.tr(),
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'reminderFormBodyField'.tr(),
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'reminderFormTime'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeLabel(context, _hour, _minute),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4FD6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  _isEdit ? 'reminderFormUpdate'.tr() : 'reminderFormSave'.tr(),
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
}

String _compactTime(int hour, int minute) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12\n${hour >= 12 ? 'PM' : 'AM'}';
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