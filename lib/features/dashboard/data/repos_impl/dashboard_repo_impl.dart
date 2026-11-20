import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../returns/data/models/return_model.dart';
import '../../../sales/data/models/sale_model.dart';
import '../repos/dashboard_repo.dart';
import 'package:hesba/core/services/app_logger.dart';
import 'package:hesba/core/services/shop_id_resolver.dart';

class DashboardRepoImpl implements DashboardRepo {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DashboardRepoImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  String? get _uid => _auth.currentUser?.uid;

  /// Get today's start (00:00:00) as Timestamp.
  Timestamp get _todayStart {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return Timestamp.fromDate(start);
  }

  /// Get today's end (23:59:59.999) as Timestamp.
  Timestamp get _todayEnd {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return Timestamp.fromDate(end);
  }

  /// Fetch the current user's shopId from their profile document.
  Future<String?> _getShopIdInternal() =>
      resolveCachedShopId(firestore: _firestore, auth: _auth);

  @override
  Future<String?> getShopId() => _getShopIdInternal();

  /// Use a shopId the caller already resolved, otherwise look it up once.
  Future<String?> _resolveShop(String? shopId) =>
      shopId != null ? Future.value(shopId) : _getShopIdInternal();

  @override
  Future<double> getTodaySalesTotal({String? shopId}) async {
    final resolved = await _resolveShop(shopId);
    if (resolved == null) return 0;

    final snapshot = await _firestore
        .collection('sales')
        .where('shopId', isEqualTo: resolved)
        .where('createdAt', isGreaterThanOrEqualTo: _todayStart)
        .where('createdAt', isLessThanOrEqualTo: _todayEnd)
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['total'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  @override
  Future<Map<String, double>> getTodaySalesByMethod({String? shopId}) async {
    final resolved = await _resolveShop(shopId);
    if (resolved == null) return {};

    final snapshot = await _firestore
        .collection('sales')
        .where('shopId', isEqualTo: resolved)
        .where('createdAt', isGreaterThanOrEqualTo: _todayStart)
        .where('createdAt', isLessThanOrEqualTo: _todayEnd)
        .get();

    final byMethod = <String, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      // الفواتير بلا وسيلة دفع تُجمع تحت '' حتى لا يختفي إجماليها.
      final method = (data['paymentMethod'] as String?)?.trim() ?? '';
      byMethod[method] =
          (byMethod[method] ?? 0) + ((data['total'] as num?)?.toDouble() ?? 0);
    }
    return byMethod;
  }

  @override
  Future<double> getTodayReturnsTotal({String? shopId}) async {
    final resolved = await _resolveShop(shopId);
    if (resolved == null) return 0;

    final snapshot = await _firestore
        .collection('returns')
        .where('shopId', isEqualTo: resolved)
        .where('createdAt', isGreaterThanOrEqualTo: _todayStart)
        .where('createdAt', isLessThanOrEqualTo: _todayEnd)
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['total'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  @override
  Future<int> getTodayReturnsCount({String? shopId}) async {
    final resolved = await _resolveShop(shopId);
    if (resolved == null) return 0;
    final snapshot = await _firestore
        .collection('returns')
        .where('shopId', isEqualTo: resolved)
        .where('createdAt', isGreaterThanOrEqualTo: _todayStart)
        .where('createdAt', isLessThanOrEqualTo: _todayEnd)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  @override
  Future<double> getTodayExpensesTotal({String? shopId}) async {
    final resolved = await _resolveShop(shopId);
    if (resolved == null) return 0;

    final snapshot = await _firestore
        .collection('expenses')
        .where('shopId', isEqualTo: resolved)
        .where('date', isGreaterThanOrEqualTo: _todayStart)
        .where('date', isLessThanOrEqualTo: _todayEnd)
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      // القوالب المتكررة ليست مصروفات فعلية — لا تُحتسب.
      final recurrence = (doc.data()['recurrence'] as String?) ?? 'none';
      if (recurrence != 'none') continue;
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  @override
  Future<int> getProductsCount({String? shopId}) async {
    final resolved = await _resolveShop(shopId);
    if (resolved == null) return 0;

    final snapshot = await _firestore
        .collection('products')
        .where('shopId', isEqualTo: resolved)
        .where('isActive', isEqualTo: true)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  @override
  Future<int> getLowStockProductsCount({String? shopId}) async {
    final resolved = await _resolveShop(shopId);
    if (resolved == null) return 0;

    final snapshot = await _firestore
        .collection('products')
        .where('shopId', isEqualTo: resolved)
        .where('isActive', isEqualTo: true)
        .get();

    int count = 0;
    for (final doc in snapshot.docs) {
      final stock = (doc.data()['stock'] as num?)?.toDouble() ?? 0;
      final threshold = (doc.data()['lowStockThreshold'] as num?)?.toDouble() ?? 5;
      if (stock <= threshold) count++;
    }
    return count;
  }

  @override
  Stream<({String? name, String? imageUrl})> watchShopIdentity() {
    if (_uid == null) return Stream.value((name: null, imageUrl: null));
    return _firestore.collection('users').doc(_uid).snapshots().map((snap) {
      if (!snap.exists) return (name: null, imageUrl: null);
      return (
        name: snap.data()?['shopName'] as String?,
        imageUrl: snap.data()?['shopImageUrl'] as String?,
      );
    });
  }

  @override
  Future<SaleModel?> getLastSale(String shopId) async {
    final snap = await _firestore
        .collection(AppConstants.salesCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    try {
      return SaleModel.fromJson(snap.docs.first.data());
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/dashboard/data/repos_impl/dashboard_repo_impl.dart', logErr, logSt, severity: LoggingSeverity.warning);
      return null;
    }
  }

  @override
  Future<ReturnModel?> getLastReturn(String shopId) async {
    final snap = await _firestore
        .collection(AppConstants.returnsCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    try {
      return ReturnModel.fromJson(snap.docs.first.data());
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/dashboard/data/repos_impl/dashboard_repo_impl.dart', logErr, logSt, severity: LoggingSeverity.warning);
      return null;
    }
  }

  @override
  Future<ExpenseModel?> getLastExpense(String shopId) async {
    final col = _firestore.collection(AppConstants.expensesCollection);
    late final QuerySnapshot<Map<String, dynamic>> snap;
    try {
      // المحاولة الأساسية (تحتاج composite index).
      snap = await col
          .where('shopId', isEqualTo: shopId)
          .orderBy('date', descending: true)
          .limit(5)
          .get();
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/dashboard/data/repos_impl/dashboard_repo_impl.dart', logErr, logSt, severity: LoggingSeverity.warning);
      // الـ index ناقص: fallback لقراءة بدون where + فلترة محلية.
      snap = await col.orderBy('date', descending: true).limit(20).get();
    }
    for (final doc in snap.docs) {
      try {
        final expense = ExpenseModel.fromJson(doc.data());
        // القوالب المتكررة ليست حركات فعلية — نتخطاها.
        if (expense.isTemplate) continue;
        if (expense.shopId == shopId) return expense;
      } catch (logErr, logSt) {
        AppLogger.nonFatal('features/dashboard/data/repos_impl/dashboard_repo_impl.dart', logErr, logSt, severity: LoggingSeverity.warning);
        // Corrupt doc: skipped instead of breaking the read.
      }
    }
    return null;
  }
}
