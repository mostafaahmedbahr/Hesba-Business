import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/supplier_model.dart';
import '../supplier_contact.dart';

/// أزرار الإجراءات أسفل تفاصيل المورد (اتصال/واتساب/نسخ + تعديل/حذف).
class SupplierActionButtons extends StatelessWidget {
  final SupplierModel supplier;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool busy;

  const SupplierActionButtons({
    super.key,
    required this.supplier,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = SupplierContact.hasPhone(supplier.phone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _BigAction(
                icon: Icons.call_rounded,
                label: 'supplierCall'.tr(),
                color: AppTheme.successDark,
                enabled: hasPhone,
                onTap: () => SupplierContact.call(context, supplier.phone),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _BigAction(
                icon: Icons.chat_rounded,
                label: 'supplierWhatsApp'.tr(),
                color: const Color(0xFF25D366),
                enabled: hasPhone,
                onTap: () => SupplierContact.whatsapp(context, supplier.phone),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _BigAction(
                icon: Icons.copy_rounded,
                label: 'supplierCopyPhone'.tr(),
                color: AppTheme.violetDeep,
                enabled: true,
                onTap: () => SupplierContact.copyPhone(context, supplier.phone),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _BigAction(
                icon: Icons.edit_outlined,
                label: 'suppliersEdit'.tr(),
                color: AppTheme.primaryColor,
                enabled: !busy,
                onTap: onEdit,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _BigAction(
                icon: Icons.delete_outline_rounded,
                label: 'supplierDelete'.tr(),
                color: AppTheme.danger,
                enabled: !busy,
                onTap: onDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BigAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _BigAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withValues(alpha: 0.16)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18.sp, color: color),
              SizedBox(height: 4.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
