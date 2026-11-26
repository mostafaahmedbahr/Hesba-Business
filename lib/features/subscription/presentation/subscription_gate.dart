import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/services/user_role_service.dart';
import '../../../core/extensions/log_util.dart';
import '../../../core/utils/toast.dart';
import '../../../core/router/app_routes.dart';
import '../data/models/subscription_model.dart';
import '../data/repos/subscription_repo.dart';
import 'widgets/subscription_blocked_dialog.dart';
import 'package:hesba/core/services/app_logger.dart';
import 'package:easy_localization/easy_localization.dart';

/// The one check every Add / Edit / Delete goes through before it runs.
///
/// Returns true when the write may proceed. Otherwise it shows a dialog
/// explaining why the shop is read-only; when the user taps "view plans"
/// the subscription screen opens. Always returns false on the blocked path.
class SubscriptionGate {
  const SubscriptionGate._();

  static SubscriptionRepo get _repo => sl<SubscriptionRepo>();

  static Future<bool> ensureCanModify(BuildContext context) async {
    // الموظف لا يملك اشتراكًا خاصًا به؛ اشتراك المحل هو المعتمد،
    // وقواعد Firestore تتحقق منه فعليًا عند الكتابة.
    if (sl<UserRoleService>().isStaff) return true;

    SubscriptionModel subscription;
    try {
      subscription = await _repo.getSubscription();
    } catch (error, logSt) {
      AppLogger.nonFatal('features/subscription/presentation/subscription_gate.dart', error, logSt, severity: LoggingSeverity.warning);
      logWarning('[SubscriptionGate] status unavailable: $error');

      // A cached decision (same session) is still better than blindly allowing.
      final cached = _repo.cached;
      if (cached != null && !cached.canModifyData) {
        if (!context.mounted) return false;
        final goPlans = await SubscriptionBlockedDialog.show(
          context,
          messageKey: cached.blockedMessageKey,
        );
        if (goPlans && context.mounted) {
          await Navigator.pushNamed(context, AppRoutes.subscription);
        }
        return false;
      }

      // Permission-denied is an authoritative refusal — never fail open on it.
      final lower = error.toString().toLowerCase();
      if (lower.contains('permission-denied') ||
          lower.contains('permission denied')) {
        if (context.mounted) {
          AppToast.error(
            context,
            'الصلاحية مرفوضة: تأكد من تفعيل حسابك وارتباطه بالمحل وسريان الاشتراك.'.tr(),
          );
        }
        return false;
      }

      // Pure network failure with no cached decision: Firestore rules remain
      // the authoritative server-side boundary, so keep the workflow usable.
      return cached?.canModifyData ?? true;
    }

    if (subscription.canModifyData) return true;
    if (!context.mounted) return false;

    final goPlans = await SubscriptionBlockedDialog.show(
      context,
      messageKey: subscription.blockedMessageKey,
    );
    if (!context.mounted) return false;

    if (goPlans) {
      await Navigator.pushNamed(context, AppRoutes.subscription);
    }
    return false;
  }

  /// Same as [ensureCanModify], but only runs [onAllowed] when the account may
  /// change data. Keeps one-line call sites in button handlers readable.
  static Future<void> run(
    BuildContext context,
    Future<void> Function() onAllowed,
  ) async {
    if (await ensureCanModify(context)) {
      await onAllowed();
    }
  }
}
