import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/log_util.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/toast.dart';
import '../data/models/subscription_model.dart';
import '../data/repos/subscription_repo.dart';

/// The one check every Add / Edit / Delete goes through before it runs.
///
/// Returns true when the write may proceed. Otherwise it explains why in a
/// toast, opens the subscription screen and returns false.
class SubscriptionGate {
  const SubscriptionGate._();

  static SubscriptionRepo get _repo => sl<SubscriptionRepo>();

  static Future<bool> ensureCanModify(BuildContext context) async {
    SubscriptionModel subscription;
    try {
      subscription = await _repo.getSubscription();
    } catch (error) {
      // The status could not be read. Let the action continue rather than
      // freeze the app on a flaky connection; the security rules are the
      // authoritative check server side.
      logWarning('[SubscriptionGate] status unavailable: $error');
      return true;
    }

    if (subscription.canModifyData) return true;
    if (!context.mounted) return false;

    AppToast.warning(context, subscription.blockedMessageKey.tr());
    await Navigator.pushNamed(context, AppRoutes.subscription);
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
