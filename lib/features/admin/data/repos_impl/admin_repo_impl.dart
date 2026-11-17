import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../features/subscription/data/models/subscription_model.dart';
import '../../../../features/subscription/data/models/subscription_request_model.dart';
import '../../../../features/reports/data/reports_calculator.dart';
import '../../../../features/returns/data/models/return_model.dart';
import '../../../../features/sales/data/models/sale_model.dart';
import '../../../../core/models/admin_settings.dart';
import '../models/profit_summary.dart';
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
  static const String _feedback = 'feedback';

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

  // ── Profit ──────────────────────────────────────────────────

  static const int _profitPageSize = 1000;
  static const int _profitMaxSales = 20000;
  static const int _profitMaxReturns = 10000;

  /// Platform-wide rollup computed with the SAME rules engine as the
  /// per-shop Reports screen (`ReportsCalculator`):
  ///  - revenue = Σ sale.total (بعد الخصم), returns deducted for profit;
  ///  - COGS from the per-line snapshot ONLY — a missing snapshot is never
  ///    back-filled with the product's current cost price;
  ///  - returns cancel the cost of returned goods, looked up from the
  ///    original sale.
  /// Numbers therefore reconcile with the per-shop reports for the same
  /// underlying documents, up to the scan caps ([capped]).
  @override
  Future<ProfitSummary> profitSummary() async {
    final sales = <SaleModel>[];
    var capped = false;

    Query<Map<String, dynamic>> query = firestore
        .collection('sales')
        .orderBy(FieldPath.documentId)
        .limit(_profitPageSize);

    while (true) {
      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      for (final doc in snap.docs) {
        sales.add(SaleModel.fromJson(doc.data()));
        if (sales.length >= _profitMaxSales) {
          capped = true;
          break;
        }
      }

      if (capped || snap.docs.length < _profitPageSize) break;
      query = firestore
          .collection('sales')
          .orderBy(FieldPath.documentId)
          .startAfterDocument(snap.docs.last)
          .limit(_profitPageSize);
    }

    final returns = <ReturnModel>[];
    Query<Map<String, dynamic>> rQuery = firestore
        .collection('returns')
        .orderBy(FieldPath.documentId)
        .limit(_profitPageSize);

    while (true) {
      final snap = await rQuery.get();
      if (snap.docs.isEmpty) break;

      for (final doc in snap.docs) {
        returns.add(ReturnModel.fromJson(doc.data()));
        if (returns.length >= _profitMaxReturns) {
          capped = true;
          break;
        }
      }

      if (capped || snap.docs.length < _profitPageSize) break;
      rQuery = firestore
          .collection('returns')
          .orderBy(FieldPath.documentId)
          .startAfterDocument(snap.docs.last)
          .limit(_profitPageSize);
    }

    // Exact same math as the per-shop Reports screen, over the whole book.
    final metrics = ReportsCalculator.calculate(
      sales: sales,
      returns: returns,
      expenses: const [],
      start: DateTime(1970),
      end: DateTime(3000),
    );

    // Monthly series with the identical rules (returns attributed to the
    // month they happened, COGS from the same snapshot logic).
    final salesById = <String, SaleModel>{
      for (final sale in sales)
        if (sale.saleId.isNotEmpty) sale.saleId: sale,
    };
    final profitByMonth = <String, int>{};
    final revenueByMonth = <String, int>{};

    String monthKey(DateTime dt) =>
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

    for (final sale in sales) {
      final key = monthKey(sale.createdAt);
      var saleCogs = 0.0;
      for (final item in sale.items) {
        if (item.costPrice > 0) saleCogs += item.costPrice * item.quantity;
      }
      revenueByMonth[key] = (revenueByMonth[key] ?? 0) + sale.total.round();
      profitByMonth[key] =
          (profitByMonth[key] ?? 0) + (sale.total - saleCogs).round();
    }

    for (final ret in returns) {
      final key = monthKey(ret.createdAt);
      final original = ret.originalSaleId == null
          ? null
          : salesById[ret.originalSaleId!];
      var returnedCogs = 0.0;
      for (final item in ret.items) {
        double? unitCost;
        if (original != null) {
          for (final saleItem in original.items) {
            if (item.productId.isNotEmpty &&
                saleItem.productId == item.productId) {
              unitCost = saleItem.costPrice;
              break;
            }
          }
          if (unitCost == null && item.productName.isNotEmpty) {
            for (final saleItem in original.items) {
              if (saleItem.productName == item.productName) {
                unitCost = saleItem.costPrice;
                break;
              }
            }
          }
        }
        if (unitCost != null && unitCost > 0) {
          returnedCogs += unitCost * item.quantity;
        }
      }
      revenueByMonth[key] = (revenueByMonth[key] ?? 0) - ret.total.round();
      profitByMonth[key] =
          (profitByMonth[key] ?? 0) - (ret.total - returnedCogs).round();
    }

    return ProfitSummary(
      revenue: metrics.netSales,
      returnsTotal: metrics.returnsTotal,
      cost: metrics.cogs,
      profit: metrics.grossProfit,
      salesCounted: sales.length,
      returnsCounted: returns.length,
      capped: capped,
      unknownCostLines: (metrics.saleLinesTotal - metrics.saleLinesWithCost) +
          (metrics.returnLinesTotal - metrics.returnLinesWithCost),
      profitByMonth: profitByMonth,
      revenueByMonth: revenueByMonth,
    );
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
  Future<QuerySnapshot<Map<String, dynamic>>> getFeedbackPage({
    DocumentSnapshot? startAfter,
  }) {
    // orderBy single field — no composite index needed.
    var query = firestore.collection(_feedback).orderBy('createdAt', descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return query.limit(_page).get();
  }

  @override
  Future<void> setFeedbackHandled(String id, bool handled) {
    return firestore.collection(_feedback).doc(id).update({
      'handled': handled,
      'handledAt': handled ? FieldValue.serverTimestamp() : null,
    });
  }

  @override
  Future<void> deleteFeedback(String id) =>
      firestore.collection(_feedback).doc(id).delete();

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getShop(String shopId) =>
      firestore.collection('shops').doc(shopId).get();

  @override
  Future<int> countShopDocs(
      {required String collection, required String shopId}) async {
    final snap = await firestore
        .collection(collection)
        .where('shopId', isEqualTo: shopId)
        .limit(100)
        .get();
    return snap.size;
  }

  @override
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getShopItems(
      {required String collection, required String shopId}) async {
    final snap = await firestore
        .collection(collection)
        .where('shopId', isEqualTo: shopId)
        .limit(50)
        .get();
    return snap.docs;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActivityLogs() {
    return firestore
        .collection(_activity)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  @override
  Future<void> signInAdmin(String email, String password) {
    // Throws FirebaseAuthException on bad credentials — the cubit maps it.
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOutAdmin() => auth.signOut();

  @override
  String? currentAdminEmail() => auth.currentUser?.email;

  @override
  Future<void> setShopSuspended(
      {required String userId, required bool suspended}) async {
    final now = Timestamp.now();
    await firestore
        .collection(_users)
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .set({'suspended': suspended, 'updatedAt': now},
            SetOptions(merge: true));
    await firestore.collection(_subscriptions).doc(userId).set(
        {'suspended': suspended, 'updatedAt': now}, SetOptions(merge: true));
    await appendActivity(
      action: suspended ? 'subscription_suspended' : 'subscription_unsuspended',
      description: suspended
          ? 'Admin suspended shop $userId'
          : 'Admin re-activated shop $userId',
    );
  }

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
      final reqSnap = await tx.get(requestRef);
      final reqData = reqSnap.data();
      if (!reqSnap.exists || reqData == null) {
        throw StateError('طلب الاشتراك غير موجود');
      }
      // Idempotency guard: re-approving an already-decided request must not
      // extend the plan a second time.
      if (reqData['status'] != SubscriptionRequestModel.statusPending) {
        throw StateError(
            'هذا الطلب ليس قيد المراجعة (الحالة: ${reqData['status']})');
      }
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
        // Keep the admin kill-switch as it was — approving a renewal must
        // not silently lift a suspended shop.
        suspended: stored.suspended,
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
          'lastRequestId': updated.lastRequestId,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
      tx.update(requestRef, {
        'status': SubscriptionRequestModel.statusApproved,
        'reviewedAt': Timestamp.fromDate(now),
      });
    });
    try {
      await appendActivity(
        action: 'subscription_approved',
        description: 'Admin approved ${request.plan.id} for ${request.shopName}',
        extra: {'userId': request.userId, 'requestId': request.requestId},
      );
    } catch (_) {
      // The approval itself committed; the activity log is best effort.
    }
  }

  @override
  Future<void> rejectRequest(SubscriptionRequestModel request, String reason) async {
    final now = DateTime.now();
    final userRef = firestore.collection(_users).doc(request.userId);
    final subRef = userRef.collection('subscription').doc('current');
    final requestRef = firestore.collection(_requests).doc(request.requestId);

    await firestore.runTransaction((tx) async {
      final reqSnap = await tx.get(requestRef);
      final reqData = reqSnap.data();
      if (!reqSnap.exists || reqData == null) {
        throw StateError('طلب الاشتراك غير موجود');
      }
      // Idempotency guard: a decided request cannot be rejected again.
      if (reqData['status'] != SubscriptionRequestModel.statusPending) {
        throw StateError(
            'هذا الطلب ليس قيد المراجعة (الحالة: ${reqData['status']})');
      }
      final subSnap = await tx.get(subRef);
      final stored = SubscriptionModel.fromJson(subSnap.data() ?? const {});

      // A live period (trial or paid) ALWAYS survives a rejection: the shop
      // keeps what it already paid for. Only an ended period becomes
      // read-only `rejected`.
      final end = stored.endDate;
      final hasLivePeriod = end != null && end.isAfter(now);
      final restored = stored.copyWith(
        status: hasLivePeriod
            ? (stored.isTrial ? SubscriptionStatus.trial : SubscriptionStatus.active)
            : SubscriptionStatus.rejected,
        updatedAt: now,
      );

      tx.update(requestRef, {
        'status': SubscriptionRequestModel.statusRejected,
        'reviewedAt': Timestamp.fromDate(now),
        'adminNote': reason,
      });
      tx.set(subRef, restored.toJson(), SetOptions(merge: true));
      // Mirror: restored state — never the *requested plan*; the mirror must
      // not diverge from the users-doc.
      tx.set(
        firestore.collection(_subscriptions).doc(request.userId),
        {
          'userId': request.userId,
          'status': restored.status.id,
          'plan': restored.plan?.id,
          'isTrial': restored.isTrial,
          'startDate': restored.startDate == null ? null : Timestamp.fromDate(restored.startDate!),
          'endDate': restored.endDate == null ? null : Timestamp.fromDate(restored.endDate!),
          'lastRequestId': request.requestId,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
    });
    try {
      await appendActivity(
        action: 'subscription_rejected',
        description: 'Admin rejected a request for ${request.shopName}${reason.isEmpty ? '' : ': $reason'}',
        extra: {'userId': request.userId, 'requestId': request.requestId},
      );
    } catch (_) {
      // The rejection itself committed; the activity log is best effort.
    }
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
