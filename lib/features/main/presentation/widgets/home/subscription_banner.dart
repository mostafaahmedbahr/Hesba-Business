import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/services/app_settings_service.dart';
import '../../../../../core/services/feature_flags_service.dart';
import '../../../../../core/theme/app_theme.dart';

/// Opens the subscription screen. Always visible so the trial countdown and
/// the plans are one tap away.
///
/// The hint text (trial length + cheapest plan price) is read live from the
/// dashboard settings via [AppSettingsService] — editing them there updates
/// this banner on the next refresh.
class SubscriptionBanner extends StatefulWidget {
  const SubscriptionBanner({super.key});

  @override
  State<SubscriptionBanner> createState() => _SubscriptionBannerState();
}

class _SubscriptionBannerState extends State<SubscriptionBanner> {
  @override
  void initState() {
    super.initState();
    // Fetch the latest settings; on success rebuild with live values.
    // refresh() never throws, so no error handling is needed here.
    Future.wait([
      AppSettingsService.refresh(),
      FeatureFlagsService.refresh(),
    ]).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // القسم بيختفي تماماً لما الداشبورد يبعت false من Firestore.
    if (!FeatureFlagsService.showSubscriptionSection) {
      return const SizedBox.shrink();
    }
    final settings = AppSettingsService.current;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: () => Navigator.pushNamed(context, AppRoutes.subscription),
        child: Ink(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
            ),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(9.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'subscriptionTitle'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'subscriptionHomeHint'.tr(namedArgs: {
                        'days': '${settings.trialDays}',
                        'from': '${settings.monthlyPrice}',
                      }),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 11.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 26.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
