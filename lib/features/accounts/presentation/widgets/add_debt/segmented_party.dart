import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../states/accounts_state.dart';
import 'package:easy_localization/easy_localization.dart';

/// اختيار نوع الطرف في «إضافة مديونية»: عميل / مورد.
class AddDebtSegmentedParty extends StatelessWidget {
  final AccountsTab tab;
  final ValueChanged<AccountsTab> onChanged;

  const AddDebtSegmentedParty({
    super.key,
    required this.tab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          _SegmentButton(
            label: 'عميل'.tr(),
            icon: Icons.person_rounded,
            selected: tab == AccountsTab.customer,
            onTap: () => onChanged(AccountsTab.customer),
          ),
          _SegmentButton(
            label: 'مورد'.tr(),
            icon: Icons.local_shipping_rounded,
            selected: tab == AccountsTab.supplier,
            onTap: () => onChanged(AccountsTab.supplier),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: selected ? AppTheme.primaryColor : AppTheme.slateGray,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppTheme.primaryColor : AppTheme.slateGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
