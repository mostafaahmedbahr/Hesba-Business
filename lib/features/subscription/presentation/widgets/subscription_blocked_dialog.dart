import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';

/// Shown instead of a bare toast when [SubscriptionGate] blocks a write.
///
/// Explains why the shop is read-only and offers a one-tap way to the
/// subscription plans. Returns `true` when the user chose to view plans.
class SubscriptionBlockedDialog extends StatelessWidget {
  const SubscriptionBlockedDialog({super.key, required this.messageKey});

  final String messageKey;

  static Future<bool> show(BuildContext context,
      {required String messageKey}) async {
    final goPlans = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SubscriptionBlockedDialog(messageKey: messageKey),
    );
    return goPlans ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 19,
              color: AppTheme.warningAmber,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'subscriptionBlockedTitle'.tr(),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.sp),
            ),
          ),
        ],
      ),
      content: Text(
        messageKey.tr(),
        style: TextStyle(fontSize: 13.sp, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('dialogCancel'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text('subscriptionViewPlans'.tr()),
        ),
      ],
    );
  }
}
