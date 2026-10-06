import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/subscription_plan.dart';
import '../../data/repos/subscription_repo.dart';
import '../cubit/subscription_cubit.dart';
import '../states/subscription_state.dart';
import '../widgets/subscription_payment_methods.dart';
import '../widgets/subscription_plan_card.dart';
import '../widgets/subscription_receipt_upload.dart';
import '../widgets/subscription_status_header.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubscriptionCubit(sl<SubscriptionRepo>())..load(),
      child: const _SubscriptionBody(),
    );
  }
}

class _SubscriptionBody extends StatelessWidget {
  const _SubscriptionBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('subscriptionTitle'.tr())),
      body: BlocConsumer<SubscriptionCubit, SubscriptionState>(
        listener: (context, state) {
          if (state.hasError && state.messageKey != null) {
            AppToast.error(context, state.messageKey!.tr());
          }
          if (state.isSubmitted) {
            AppToast.success(context, 'subscriptionSubmitted'.tr());
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.loadStatus == SubscriptionLoadStatus.error) {
            return _LoadFailed(onRetry: () {
              context.read<SubscriptionCubit>().load();
            });
          }
          return _Content(state: state);
        },
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 44.sp, color: AppTheme.errorColor),
            SizedBox(height: 12.h),
            Text(
              'subscriptionLoadFailed'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            FilledButton(onPressed: onRetry, child: Text('retry'.tr())),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionCubit>();
    final subscription = state.subscription;

    if (state.isSubmitted) {
      return _SubmittedBody(onClose: () => Navigator.pop(context));
    }

    // Waiting for the admin: read only, no plans, no receipt, no submit.
    if (subscription?.status == SubscriptionStatus.pending) {
      return ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          SubscriptionStatusHeader(subscription: subscription!),
          SizedBox(height: 16.h),
          const _WaitingCard(
            icon: Icons.hourglass_top_rounded,
            messageKey: 'subscriptionPendingCard',
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        if (subscription != null) ...[
          SubscriptionStatusHeader(subscription: subscription),
          SizedBox(height: 16.h),
        ],
        if (subscription?.status == SubscriptionStatus.rejected) ...[
          const _WaitingCard(
            icon: Icons.info_outline_rounded,
            messageKey: 'subscriptionRejectedCard',
          ),
          SizedBox(height: 16.h),
        ],
        Text(
          'subscriptionPickPlan'.tr(),
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 4.h),
        Text(
          'subscriptionPickPlanHint'.tr(),
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
        ),
        SizedBox(height: 14.h),
        for (final plan in SubscriptionPlan.values) ...[
          SubscriptionPlanCard(
            plan: plan,
            selected: state.selectedPlan == plan,
            onTap: () => cubit.selectPlan(plan),
          ),
          SizedBox(height: 12.h),
        ],
        if (state.selectedPlan != null) ...[
          SizedBox(height: 6.h),
          Text(
            'paymentSectionTitle'.tr(),
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 12.h),
          SubscriptionPaymentMethods(
            amount: state.selectedPlan!.price,
            selected: state.selectedPaymentMethod,
            onSelected: cubit.selectPaymentMethod,
          ),
          SizedBox(height: 16.h),
          SubscriptionReceiptUpload(
            receiptUrl: state.receiptUrl,
            uploading: state.isUploadingReceipt,
            onPick: (source) => cubit.pickReceipt(source),
          ),
          SizedBox(height: 22.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: FilledButton(
              onPressed: state.canSubmit && !state.isSubmitting
                  ? () => cubit.submit()
                  : null,
              child: state.isSubmitting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'subscriptionSubmit'.tr(),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ],
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.icon, required this.messageKey});

  final IconData icon;
  final String messageKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24.sp, color: AppTheme.primaryColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              messageKey.tr(),
              style: TextStyle(fontSize: 13.5.sp, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedBody extends StatelessWidget {
  const _SubmittedBody({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 44.sp,
                color: AppTheme.successColor,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'subscriptionSubmittedTitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 10.h),
            Text(
              'subscriptionSubmittedHint'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5.sp, height: 1.7),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: FilledButton(
                onPressed: onClose,
                child: Text(
                  'done'.tr(),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
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
