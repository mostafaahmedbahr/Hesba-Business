import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/supplier_model.dart';

/// شريط عنوان شاشة تفاصيل المورد (تدرّج بنفسجي + أزرار تعديل/حذف).
class SupplierDetailsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final SupplierModel? supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SupplierDetailsAppBar({
    super.key,
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF3B0764),
              AppTheme.violetDeep,
              AppTheme.violetSoft,
            ],
          ),
        ),
      ),
      title: Text(
        'suppliersDetails'.tr(),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      actions: [
        if (supplier != null)
          IconButton(
            tooltip: 'suppliersEdit'.tr(),
            icon: const Icon(Icons.edit_rounded),
            onPressed: onEdit,
          ),
        if (supplier != null)
          IconButton(
            tooltip: 'supplierDelete'.tr(),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: onDelete,
          ),
      ],
    );
  }
}
