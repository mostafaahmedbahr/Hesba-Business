import 'package:image_picker/image_picker.dart';

import '../models/subscription_model.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_request_model.dart';

/// Storage for the manual, admin-reviewed subscription system.
///
/// Reads go through `users/{uid}/subscription`, submissions are written to
/// `subscription_requests` and reviewed by the admin in the Firebase console.
abstract class SubscriptionRepo {
  /// Last known subscription, or null when it was never loaded.
  SubscriptionModel? get cached;

  /// Reads the current subscription, creating the free 7 day trial the first
  /// time an account is seen.
  ///
  /// [refresh] bypasses the short-lived memory cache the guard relies on.
  Future<SubscriptionModel> getSubscription({bool refresh = false});

  /// Streams the subscription document so a screen can stay in sync.
  Stream<SubscriptionModel> watchSubscription();

  /// Writes the free trial for a freshly registered account.
  ///
  /// Best effort: if it fails the account still gets its trial on the first
  /// read, so registration is never blocked by it.
  Future<void> startTrialForNewUser({
    required String userId,
    required DateTime createdAt,
  });

  /// Picks a receipt image WITHOUT uploading it. The upload is deferred to
  /// submit time so a failed/abandoned request never leaves an unattended
  /// payment screenshot on Cloudinary.
  Future<XFile?> pickPaymentReceipt({required ImageSource source});

  /// Uploads an already-picked receipt and returns its secure URL.
  /// [source] is kept for backwards compatibility; when [file] is provided
  /// it takes precedence and no second picker is opened.
  Future<String?> uploadPaymentReceipt({ImageSource? source, XFile? file});

  /// Creates a `pending` subscription request and flags the account as
  /// waiting for review.
  Future<SubscriptionRequestModel> submitRequest({
    required SubscriptionPlan plan,
    required SubscriptionPaymentMethod paymentMethod,
    required String paymentProofUrl,
  });

  /// The request this account is waiting on, if any.
  Future<SubscriptionRequestModel?> getRequest(String requestId);
}
