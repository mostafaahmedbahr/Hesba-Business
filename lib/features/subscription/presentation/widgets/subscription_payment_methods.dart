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
    final bodyColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: method.brandColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                method.brandMark,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
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
                  SizedBox(height: 6.h),
                  InkWell(
                    onTap: () => _copyNumber(context),
                    borderRadius: BorderRadius.circular(9.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : bodyColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(9.r),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryColor.withValues(alpha: 0.35)
                              : theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              method.number,
                              style: TextStyle(
                                fontSize: 14.sp,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            Icons.copy_rounded,
                            size: 16.sp,
                            color: theme.hintColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyNumber(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: method.number));
    if (context.mounted) {
      AppToast.success(context, 'paymentCopied'.tr());
    }
  }
}
