import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/subscription_model.dart';

/// Answers "am I allowed to edit, and until when" in one glance.
class SubscriptionStatusHeader extends StatelessWidget {
  const SubscriptionStatusHeader({super.key, required this.subscription});

  final SubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    final status = subscription.effectiveStatus;
    final color = _colorFor(status);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(_iconFor(status), size: 18.sp, color: color),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'subscriptionStatus${_keyFor(status)}'.tr(),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              if (subscription.remainingDays > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 9.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    'subscriptionDaysLeft'.tr(
                      args: ['${subscription.remainingDays}'],
                    ),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          if (_subtitle() != null) ...[
            SizedBox(height: 10.h),
            Text(
              _subtitle()!,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: theme.textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _subtitle() {
    final end = subscription.endDate;
    final date =
        end == null ? null : DateFormat('yyyy/MM/dd').format(end);
    return switch (subscription.effectiveStatus) {
      SubscriptionStatus.trial => date == null
          ? null
          : 'subscriptionTrialRemaining'
              .tr(args: ['${subscription.remainingDays}', date]),
      SubscriptionStatus.active => date == null
          ? null
          : 'subscriptionActiveUntil'.tr(args: [date]),
      SubscriptionStatus.pending => 'subscriptionPendingHint'.tr(),
      SubscriptionStatus.rejected => 'subscriptionRejectedHint'.tr(),
      SubscriptionStatus.expired => 'subscriptionExpiredHint'.tr(),
    };
  }

  static Color _colorFor(SubscriptionStatus status) {
    return switch (status) {
      SubscriptionStatus.trial => AppTheme.secondaryColor,
      SubscriptionStatus.active => AppTheme.successColor,
      SubscriptionStatus.pending => AppTheme.primaryColor,
      SubscriptionStatus.rejected => AppTheme.errorColor,
      SubscriptionStatus.expired => AppTheme.textSecondary,
    };
  }

  static IconData _iconFor(SubscriptionStatus status) {
    return switch (status) {
      SubscriptionStatus.trial => Icons.star_outline_rounded,
      SubscriptionStatus.active => Icons.verified_rounded,
      SubscriptionStatus.pending => Icons.hourglass_top_rounded,
      SubscriptionStatus.rejected => Icons.cancel_rounded,
      SubscriptionStatus.expired => Icons.lock_clock_rounded,
    };
  }

  static String _keyFor(SubscriptionStatus status) {
    return switch (status) {
      SubscriptionStatus.trial => 'Trial',
      SubscriptionStatus.active => 'Active',
      SubscriptionStatus.pending => 'Pending',
      SubscriptionStatus.rejected => 'Rejected',
      SubscriptionStatus.expired => 'Expired',
    };
  }
}
