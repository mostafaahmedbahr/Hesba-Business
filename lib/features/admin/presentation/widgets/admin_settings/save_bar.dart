import 'package:flutter/material.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:easy_localization/easy_localization.dart';

/// شريط الحفظ الثابت أسفل الشاشة: حالة التغييرات + زر التجاهل + زر الحفظ.
class AdminSettingsSaveBar extends StatelessWidget {
  const AdminSettingsSaveBar({
    super.key,
    required this.dirty,
    required this.saving,
    required this.onSave,
    required this.onDiscard,
  });

  final bool dirty;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final statusColor = saving
        ? AppTheme.primaryColor
        : dirty
            ? AdminColors.warning
            : AdminColors.success;
    final statusIcon = saving
        ? Icons.sync_rounded
        : dirty
            ? Icons.edit_note_rounded
            : Icons.check_circle_outline_rounded;
    final statusLabel = saving
        ? 'جاري حفظ التغييرات...'.tr()
        : dirty
            ? 'لديك تغييرات غير محفوظة'.tr()
            : 'كل الإعدادات محفوظة'.tr();

    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, size: 17, color: statusColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );

    final saveButton = ElevatedButton.icon(
      onPressed: saving || !dirty ? null : onSave,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminRadius.button),
        ),
      ),
      icon: saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save_outlined, size: 19),
      label: Text(saving ? 'جاري الحفظ...'.tr() : 'حفظ الإعدادات'.tr()),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminColors.surface(context),
        border: Border(top: BorderSide(color: AdminColors.border(context))),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(
          horizontal: AdminSpace.md,
          vertical: AdminSpace.sm,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inline = constraints.maxWidth >= 600;
            if (inline) {
              return Row(
                children: [
                  Expanded(child: status),
                  TextButton(
                    onPressed: dirty && !saving ? onDiscard : null,
                    child: Text('تجاهل التغييرات'.tr()),
                  ),
                  const SizedBox(width: AdminSpace.xs),
                  saveButton,
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: status),
                    if (dirty && !saving)
                      TextButton.icon(
                        onPressed: onDiscard,
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: Text(
                          'تجاهل'.tr(),
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AdminSpace.xs),
                SizedBox(width: double.infinity, child: saveButton),
              ],
            );
          },
        ),
      ),
    );
  }
}
