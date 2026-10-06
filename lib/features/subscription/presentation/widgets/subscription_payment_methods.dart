import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../data/models/subscription_plan.dart';

/// The three manual channels the customer transfers to, plus how much.
class SubscriptionPaymentMethods extends StatelessWidget {
  const SubscriptionPaymentMethods({
    super.key,
    required this.amount,
    required this.selected,
    required this.onSelected,
  });

  final int amount;
  final SubscriptionPaymentMethod? selected;
  final ValueChanged<SubscriptionPaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'paymentAmountDue'.tr(args: ['$amount']),
          style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4.h),
        Text(
          'paymentPickChannel'.tr(),
          style: TextStyle(fontSize: 12.sp, color: theme.hintColor),
        ),
        SizedBox(height: 12.h),
        for (final method in SubscriptionPaymentMethod.values) ...[
          _MethodTile(
            method: method,
            selected: selected == method,
            onTap: () => onSelected(method),
          ),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primarySoft
              : theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: (selected
                        ? AppTheme.primaryColor
                        : theme.hintColor)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                method.icon,
                size: 18.sp,
                color: selected ? AppTheme.primaryColor : theme.hintColor,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.labelKey.tr(),
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    method.number,
                    style: TextStyle(
                      fontSize: 13.sp,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'paymentCopy'.tr(),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: method.number));
                if (context.mounted) {
                  AppToast.success(context, 'paymentCopied'.tr());
                }
              },
              icon: Icon(Icons.copy_rounded, size: 18.sp),
            ),
          ],
        ),
      ),
    );
  }
}
