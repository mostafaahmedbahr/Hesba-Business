import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/log_util.dart';
import '../../../../core/services/cloudinary_image_service.dart';
import '../models/subscription_model.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_request_model.dart';
import '../repos/subscription_repo.dart';

/// Firestore implementation of the manual subscription system.
///
/// Layout:
///   users/{uid}/subscription/current   the account's subscription
///   subscription_requests/{id}         one row per submitted receipt
class SubscriptionRepoImpl implements SubscriptionRepo {
  SubscriptionRepoImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required CloudinaryImageService cloudinary,
  })  : _auth = auth,
        _firestore = firestore,
        _cloudinary = cloudinary;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final CloudinaryImageService _cloudinary;

  static const String _users = 'users';
  static const String _subscription = 'subscription';
  static const String _currentDoc = 'current';
  static const String _requests = 'subscription_requests';

  /// How long the guard may reuse a value it already read, so Add / Edit /
  /// Delete checks do not hit Firestore every single tap.
  static const Duration _cacheTtl = Duration(seconds: 30);

  SubscriptionModel? _cache;
  DateTime? _cachedAt;

  @override
  SubscriptionModel? get cached => _cache;

  @override
  Future<SubscriptionModel> getSubscription({bool refresh = false}) async {
    final uid = _requireUid();
    final cached = _cache;
    if (!refresh &&
        cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return cached;
    }

    var subscription = await _read(uid);
    subscription = await _applyAdminDecision(uid, subscription);
    subscription = await _persistExpiry(uid, subscription);

    _cache = subscription;
    _cachedAt = DateTime.now();
    return subscription;
  }

  @override
  Stream<SubscriptionModel> watchSubscription() {
    final uid = _requireUid();
    return _subscriptionRef(uid).snapshots().map((snap) {
      return SubscriptionModel.fromJson(snap.data() ?? const {});
    });
  }

  @override
  Future<void> startTrialForNewUser({
    required String userId,
    required DateTime createdAt,
  }) async {
    final trial = SubscriptionModel.trialFor(createdAt: createdAt);
    await _subscriptionRef(userId).set(trial.toJson());
    await _mirrorSubscription(userId, trial);
    if (userId == _auth.currentUser?.uid) {
      _cache = trial;
      _cachedAt = DateTime.now();
    }
    logSuccess('[Subscription] free trial started for $userId');
  }

  @override
  Future<String?> uploadPaymentReceipt({required ImageSource source}) {
    return _cloudinary.uploadPaymentReceipt(source: source);
  }

  @override
  Future<SubscriptionRequestModel> submitRequest({
    required SubscriptionPlan plan,
    required SubscriptionPaymentMethod paymentMethod,
    required String paymentProofUrl,
  }) async {
    final uid = _requireUid();
    // Guarantees the subscription document exists before it is flagged.
    final subscription = await getSubscription(refresh: true);
    final profile = await _readProfile(uid);

    final requestRef = _firestore.collection(_requests).doc();
    final now = DateTime.now();
    final request = SubscriptionRequestModel(
      requestId: requestRef.id,
      userId: uid,
      ownerName: profile.ownerName,
      shopName: profile.shopName,
      phone: profile.phone,
      plan: plan,
      amount: plan.price,
      paymentMethod: paymentMethod.id,
      paymentProofUrl: paymentProofUrl,
      status: SubscriptionRequestModel.statusPending,
      createdAt: now,
    );

    final batch = _firestore.batch();
    batch.set(requestRef, request.toJson());
    batch.update(_subscriptionRef(uid), {
      'status': SubscriptionStatus.pending.id,
      'lastRequestId': requestRef.id,
      'updatedAt': Timestamp.fromDate(now),
    });
    await batch.commit();
    await _mirrorSubscription(uid, subscription.copyWith(
      status: SubscriptionStatus.pending,
      lastRequestId: requestRef.id,
      updatedAt: now,
      cachedAt: now,
    ));

    _cache = subscription.copyWith(
      status: SubscriptionStatus.pending,
      lastRequestId: requestRef.id,
      updatedAt: now,
      cachedAt: now,
    );
    _cachedAt = now;
    logSuccess('[Subscription] request ${requestRef.id} submitted by $uid');
    return request;
  }

  @override
  Future<SubscriptionRequestModel?> getRequest(String requestId) async {
    final snap = await _firestore.collection(_requests).doc(requestId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return SubscriptionRequestModel.fromJson(requestId, data);
  }

  // ── internals ────────────────────────────────────────────────────────

  Future<SubscriptionModel> _read(String uid) async {
    final snap = await _subscriptionRef(uid).get();
    if (snap.exists) {
      return SubscriptionModel.fromJson(snap.data() ?? const {});
    }
    // A brand new or pre-subscription account: hand out the free week.
    final trial = SubscriptionModel.trialFor(createdAt: DateTime.now());
    await _subscriptionRef(uid).set(trial.toJson());
    await _mirrorSubscription(uid, trial);
    logSuccess('[Subscription] trial created on first read for $uid');
    return trial;
  }

  /// Reads the reviewed request and folds its decision into the subscription.
  ///
  /// Only a `pending` subscription is waiting for an answer, so the work runs
  /// once and never rewrites an already active account.
  Future<SubscriptionModel> _applyAdminDecision(
    String uid,
    SubscriptionModel subscription,
  ) async {
    if (subscription.status != SubscriptionStatus.pending) {
      return subscription;
    }
    final requestId = subscription.lastRequestId;
    if (requestId == null) return subscription;

    final request = await getRequest(requestId);
    if (request == null || request.isPending) return subscription;

    final now = DateTime.now();
    final next = request.isApproved
        ? _activationFrom(subscription, request.plan, now)
        : subscription.copyWith(
            status: SubscriptionStatus.rejected,
            updatedAt: now,
          );

    await _subscriptionRef(uid).set(next.toJson(), SetOptions(merge: true));
    await _mirrorSubscription(uid, next);
    _cache = next.copyWith(cachedAt: now);
    _cachedAt = now;
    logSuccess('[Subscription] request $requestId -> ${request.status}');
    return next;
  }

  /// Activates a purchased plan.
  ///
  /// Days still left on the current period are kept: the new end date is
  /// appended to it instead of restarting from today. Only an ended period
  /// starts fresh.
  SubscriptionModel _activationFrom(
    SubscriptionModel subscription,
    SubscriptionPlan plan,
    DateTime now,
  ) {
    final liveEnd = subscription.livePeriodEnd;
    final hasLivePeriod = liveEnd != null && liveEnd.isAfter(now);
    final duration = Duration(days: plan.days);

    return SubscriptionModel(
      status: SubscriptionStatus.active,
      plan: plan,
      startDate: hasLivePeriod ? subscription.startDate : now,
      endDate: hasLivePeriod ? liveEnd.add(duration) : now.add(duration),
      isTrial: false,
      trialStartDate: subscription.trialStartDate,
      trialEndDate: subscription.trialEndDate,
      lastRequestId: subscription.lastRequestId,
      updatedAt: now,
    );
  }

  /// Writes the `expired` flip the next read already reports, so Firestore and
  /// the app agree without a background job.
  Future<SubscriptionModel> _persistExpiry(
    String uid,
    SubscriptionModel subscription,
  ) async {
    final stored = subscription.status;
    if (stored != SubscriptionStatus.trial &&
        stored != SubscriptionStatus.active) {
      return subscription;
    }
    if (subscription.effectiveStatus == stored) return subscription;

    final expired = subscription.copyWith(
      status: SubscriptionStatus.expired,
      updatedAt: DateTime.now(),
    );
    try {
      await _subscriptionRef(uid).set(expired.toJson(), SetOptions(merge: true));
      await _mirrorSubscription(uid, expired);
      logSuccess('[Subscription] $stored rolled over to expired');
    } catch (error) {
      // The read still answers correctly, only the stored flag lags behind.
      logWarning('[Subscription] could not persist expiry: $error');
    }
    return expired;
  }

  Future<_ProfileFields> _readProfile(String uid) async {
    try {
      final snap = await _firestore.collection(_users).doc(uid).get();
      final data = snap.data() ?? const {};
      return _ProfileFields(
        ownerName: data['ownerName'] as String? ?? '',
        shopName: data['shopName'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
      );
    } catch (error) {
      // The request must still go through with whatever we know.
      logWarning('[Subscription] profile lookup failed: $error');
      return const _ProfileFields(ownerName: '', shopName: '', phone: '');
    }
  }

  /// Denormalised copy at `subscriptions/{userId}` so the admin dashboard can
  /// list/filter by status without reading every user's subcollection.
  Future<void> _mirrorSubscription(String uid, SubscriptionModel model) async {
    try {
      await _firestore.collection('subscriptions').doc(uid).set({
        'userId': uid,
        'status': model.status.id,
        'plan': model.plan?.id,
        'isTrial': model.isTrial,
        'startDate':
            model.startDate == null ? null : Timestamp.fromDate(model.startDate!),
        'endDate': model.endDate == null ? null : Timestamp.fromDate(model.endDate!),
        'updatedAt': Timestamp.fromDate(model.updatedAt ?? DateTime.now()),
      }, SetOptions(merge: true));
    } catch (error) {
      logWarning('[Subscription] mirror write failed: $error');
    }
  }

  DocumentReference<Map<String, dynamic>> _subscriptionRef(String uid) {
    return _firestore
        .collection(_users)
        .doc(uid)
        .collection(_subscription)
        .doc(_currentDoc);
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('auth/user-not-logged-in');
    }
    return uid;
  }
}

class _ProfileFields {
  const _ProfileFields({
    required this.ownerName,
    required this.shopName,
    required this.phone,
  });

  final String ownerName;
  final String shopName;
  final String phone;
}
