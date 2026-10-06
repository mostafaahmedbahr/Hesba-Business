import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../features/subscription/data/models/subscription_model.dart';
import '../../../../features/subscription/data/models/subscription_request_model.dart';
import '../models/admin_settings.dart';
import '../repos/admin_repo.dart';

class AdminRepoImpl implements AdminRepo {
  AdminRepoImpl({required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  static const String _users = 'users';
  static const String _subscriptions = 'subscriptions';
  static const String _requests = 'subscription_requests';
  static const String _activity = 'activity_logs';
  static const String _settings = 'admin_settings';

  @override
  Future<bool> isAdmin() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await firestore.collection(_users).doc(uid).get();
      final data = doc.data() ?? const {};
      return (data['role'] as String?) == 'admin';
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<String?> watchUid() => auth.idTokenChanges().map((u) => u?.uid);

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    try {
      final agg = await query.count().get();
      return agg.count ?? 0;
    } catch (_) {
      // Fallback: scan a capped page (older rules / missing index).
      final snap = await query.limit(1000).get();
      return snap.size;
    }
  }

  @override
  Future<int> countShops() => _count(firestore.collection('shops'));
  @override
  Future<int> countProducts() => _count(firestore.collection('products'));
  @override
  Future<int> countSales() => _count(firestore.collection('sales'));
  @override
  Future<int> countExpenses() => _count(firestore.collection('expenses'));
  @override
  Future<int> countActiveSubscriptions() =>
      _count(firestore.collection(_subscriptions).where('status', isEqualTo: 'active'));
  @override
  Future<int> countTrialSubscriptions() =>
      _count(firestore.collection(_subscriptions).where('status', isEqualTo: 'trial'));
  @override
  Future<int> countExpiredSubscriptions() =>
      _count(firestore.collection(_subscriptions).where('status', isEqualTo: 'expired'));
  @override
  Future<int> countPendingRequests() =>
      _count(firestore.collection(_requests).where('status', isEqualTo: 'pending'));

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingRequestsOnce() {
    return firestore
        .collection(_requests)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  @override
  Future<Map<String, int>> subscriptionCountsByMonth({required int months}) async {
    final snap = await firestore
        .collection(_subscriptions)
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_monthCutoff(months)))
        .limit(2000)
        .get();
    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      DateTime? start;
      final s = data['startDate'];
      if (s is Timestamp) start = s.toDate();
      if (start == null) continue;
      final key = '${start.year}-${start.month.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<Map<String, int>> shopsByMonth({required int months}) async {
    final snap = await firestore
        .collection('shops')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_monthCutoff(months)))
        .limit(2000)
        .get();
    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      DateTime? created;
      final c = data['createdAt'];
      if (c is Timestamp) created = c.toDate();
      if (created == null) continue;
      final key = '${created.year}-${created.month.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<Map<String, int>> revenueByMonth({required int months}) async {
    // Single range filter only (status is filtered client-side) so no
    // composite index is required.
    final snap = await firestore
        .collection(_requests)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_monthCutoff(months)))
        .limit(2000)
        .get();
    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['status'] != 'approved') continue;
      DateTime? created;
      final c = data['createdAt'];
      if (c is Timestamp) created = c.toDate();
      if (created == null) continue;
      final key = '${created.year}-${created.month.toString().padLeft(2, '0')}';
      final amount = (data['amount'] as num?)?.toInt() ?? 0;
      counts[key] = (counts[key] ?? 0) + amount;
    }
    return counts;
  }

  /// First day of the month, [months] months ago. Honors the `months`
  /// window server-side instead of downloading whole collections.
  DateTime _monthCutoff(int months) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - months + 1, 1);
  }

  static const int _page = 20;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getShopsPage({
    DocumentSnapshot? startAfter,
    String search = '',
  }) {
    var query = firestore.collection('shops').orderBy('createdAt', descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return query.limit(_page).get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getProductsPage({DocumentSnapshot? startAfter}) {
    var query = firestore.collection('products').orderBy('createdAt', descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return query.limit(_page).get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getSalesPage({DocumentSnapshot? startAfter}) {
    var query = firestore.collection('sales').orderBy('createdAt', descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return query.limit(_page).get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getExpensesPage({DocumentSnapshot? startAfter}) {
    var query = firestore.collection('expenses').orderBy('createdAt', descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return query.limit(_page).get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getSubscriptionsPage({
    DocumentSnapshot? startAfter,
    String? status,
  }) async {
    final hasFilter = status != null && status.isNotEmpty && status != 'all';
    // where('status') + orderBy('updatedAt') يحتاج composite index يدوي.
    // عشان اللوحة تشتغل من غير إنشاء index: مع الفلترة بنعمل where فقط
    // والترتيب بيتعمل في الذاكرة داخل الـ View.
    try {
      Query<Map<String, dynamic>> query = firestore.collection(_subscriptions);
      if (hasFilter) {
        query = query.where('status', isEqualTo: status);
      } else {
        query = query.orderBy('updatedAt', descending: true);
      }
      if (startAfter != null) query = query.startAfterDocument(startAfter);
      return await query.limit(_page).get();
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      // Fallback أخير: where فقط بدون أي ترتيب سيرفر.
      Query<Map<String, dynamic>> fallback = firestore.collection(_subscriptions);
      if (hasFilter) fallback = fallback.where('status', isEqualTo: status);
      return fallback.limit(_page).get();
    }
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getRequestsPage({
    DocumentSnapshot? startAfter,
    String? status,
  }) async {
    final hasFilter = status != null && status.isNotEmpty && status != 'all';
    // نفس السبب: where('status') + orderBy('createdAt') يحتاج composite index.
    try {
      Query<Map<String, dynamic>> query = firestore.collection(_requests);
      if (hasFilter) {
        query = query.where('status', isEqualTo: status);
      } else {
        query = query.orderBy('createdAt', descending: true);
      }
      if (startAfter != null) query = query.startAfterDocument(startAfter);
      return await query.limit(_page).get();
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      Query<Map<String, dynamic>> fallback = firestore.collection(_requests);
      if (hasFilter) fallback = fallback.where('status', isEqualTo: status);
      return fallback.limit(_page).get();
    }
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getShop(String shopId) =>
      firestore.collection('shops').doc(shopId).get();

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserSubscription(String userId) =>
      firestore.collection(_users).doc(userId).collection('subscription').doc('current').get();

  @override
  Future<SubscriptionRequestModel?> getRequest(String requestId) async {
    final snap = await firestore.collection(_requests).doc(requestId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return SubscriptionRequestModel.fromJson(requestId, data);
  }

  @override
  Future<void> approveRequest(SubscriptionRequestModel request) async {
    final now = DateTime.now();
    final userRef = firestore.collection(_users).doc(request.userId);
    final requestRef = firestore.collection(_requests).doc(request.requestId);

    await firestore.runTransaction((tx) async {
      final subSnap =
          await tx.get(userRef.collection('subscription').doc('current'));
      final data = subSnap.data() ?? <String, dynamic>{};
      final stored = SubscriptionModel.fromJson(data);

      final liveEnd = stored.livePeriodEnd;
      final hasLive = liveEnd != null && liveEnd.isAfter(now);
      final duration = Duration(days: request.plan.days);
      final start = hasLive ? stored.startDate : now;
      final end = hasLive ? liveEnd.add(duration) : now.add(duration);

      final updated = SubscriptionModel(
        status: SubscriptionStatus.active,
        plan: request.plan,
        startDate: start,
        endDate: end,
        isTrial: false,
        trialStartDate: stored.trialStartDate,
        trialEndDate: stored.trialEndDate,
        lastRequestId: request.requestId,
        updatedAt: now,
      );

      tx.set(
        userRef.collection('subscription').doc('current'),
        updated.toJson(),
        SetOptions(merge: true),
      );
      tx.set(
        firestore.collection(_subscriptions).doc(request.userId),
        {
          'userId': request.userId,
          'status': updated.status.id,
          'plan': updated.plan?.id,
          'isTrial': updated.isTrial,
          'startDate': updated.startDate == null ? null : Timestamp.fromDate(updated.startDate!),
          'endDate': updated.endDate == null ? null : Timestamp.fromDate(updated.endDate!),
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
      tx.update(requestRef, {
        'status': SubscriptionRequestModel.statusApproved,
        'reviewedAt': Timestamp.fromDate(now),
      });
    });
    await appendActivity(
      action: 'subscription_approved',
      description: 'Admin approved ${request.plan.id} for ${request.shopName}',
      extra: {'userId': request.userId, 'requestId': request.requestId},
    );
  }

  @override
  Future<void> rejectRequest(SubscriptionRequestModel request, String reason) async {
    final now = DateTime.now();
    await firestore.collection(_requests).doc(request.requestId).update({
      'status': SubscriptionRequestModel.statusRejected,
      'reviewedAt': Timestamp.fromDate(now),
      'adminNote': reason,
    });
    final userRef = firestore.collection(_users).doc(request.userId);
    final subSnap = await userRef.collection('subscription').doc('current').get();
    final sub = SubscriptionModel.fromJson(subSnap.data() ?? const {});
    await userRef.collection('subscription').doc('current').set(
          sub
              .copyWith(status: SubscriptionStatus.rejected, updatedAt: now)
              .toJson(),
          SetOptions(merge: true),
        );
    await firestore.collection(_subscriptions).doc(request.userId).set({
      'userId': request.userId,
      'status': 'rejected',
      'plan': request.plan.id,
      'isTrial': false,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
    await appendActivity(
      action: 'subscription_rejected',
      description: 'Admin rejected a request for ${request.shopName}${reason.isEmpty ? '' : ': $reason'}',
      extra: {'userId': request.userId, 'requestId': request.requestId},
    );
  }

  @override
  Future<void> appendActivity({
    required String action,
    required String description,
    Map<String, dynamic>? extra,
  }) async {
    final uid = auth.currentUser?.uid;
    await firestore.collection(_activity).add({
      'action': action,
      'description': description,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      ...?extra,
    });
  }

  @override
  Future<AdminSettings> getSettings() async {
    try {
      final snap = await firestore.collection(_settings).doc('settings').get();
      final data = snap.data();
      if (data == null) return AdminSettings.defaults;
      return AdminSettings.fromJson(data);
    } catch (_) {
      return AdminSettings.defaults;
    }
  }

  @override
  Future<void> saveSettings(AdminSettings settings) async {
    await firestore.collection(_settings).doc('settings').set(settings.toJson());
  }
}
