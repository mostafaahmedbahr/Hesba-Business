import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../returns/data/models/return_model.dart';
import '../../../sales/data/models/sale_model.dart';
import '../repos/dashboard_repo.dart';

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
  Future<String?> _getShopIdInternal() async {
    if (_uid == null) return null;
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  @override
  Future<String?> getShopId() => _getShopIdInternal();

  @override
  Future<double> getTodaySalesTotal() async {
    final shopId = await _getShopIdInternal();
    if (shopId == null) return 0;

    final snapshot = await _firestore
        .collection('sales')
        .where('shopId', isEqualTo: shopId)
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
  Future<double> getTodayReturnsTotal() async {
    final shopId = await _getShopIdInternal();
    if (shopId == null) return 0;

    final snapshot = await _firestore
        .collection('returns')
        .where('shopId', isEqualTo: shopId)
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
  Future<int> getTodayReturnsCount() async {
    final shopId = await _getShopIdInternal();
    if (shopId == null) return 0;
    final snapshot = await _firestore
        .collection('returns')
        .where('shopId', isEqualTo: shopId)
        .where('createdAt', isGreaterThanOrEqualTo: _todayStart)
        .where('createdAt', isLessThanOrEqualTo: _todayEnd)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  @override
  Future<double> getTodayExpensesTotal() async {
    final shopId = await _getShopIdInternal();
    if (shopId == null) return 0;

    final snapshot = await _firestore
        .collection('expenses')
        .where('shopId', isEqualTo: shopId)
        .where('date', isGreaterThanOrEqualTo: _todayStart)
        .where('date', isLessThanOrEqualTo: _todayEnd)
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  @override
  Future<int> getProductsCount() async {
    final shopId = await _getShopIdInternal();
    if (shopId == null) return 0;

    final snapshot = await _firestore
        .collection('products')
        .where('shopId', isEqualTo: shopId)
        .where('isActive', isEqualTo: true)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  @override
  Future<int> getLowStockProductsCount() async {
    final shopId = await _getShopIdInternal();
    if (shopId == null) return 0;

    final snapshot = await _firestore
        .collection('products')
        .where('shopId', isEqualTo: shopId)
        .where('isActive', isEqualTo: true)
        .get();

    int count = 0;
    for (final doc in snapshot.docs) {
      final stock = (doc.data()['stock'] as num?)?.toInt() ?? 0;
      final threshold = (doc.data()['lowStockThreshold'] as num?)?.toInt() ?? 5;
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
  Stream<void> watchDashboardChanges() {
    final controller = StreamController<void>.broadcast();
    String? shopId;
    final subs = <StreamSubscription>[];

    void listenCollections(String sid) {
      for (final s in subs) {
        s.cancel();
      }
      subs.clear();
      subs.add(_firestore
          .collection(AppConstants.salesCollection)
          .where('shopId', isEqualTo: sid)
          .snapshots()
          .listen((_) => controller.add(null), onError: (_) {}));
      subs.add(_firestore
          .collection(AppConstants.productsCollection)
          .where('shopId', isEqualTo: sid)
          .snapshots()
          .listen((_) => controller.add(null), onError: (_) {}));
      subs.add(_firestore
          .collection(AppConstants.returnsCollection)
          .where('shopId', isEqualTo: sid)
          .snapshots()
          .listen((_) => controller.add(null), onError: (_) {}));
      subs.add(_firestore
          .collection(AppConstants.expensesCollection)
          .where('shopId', isEqualTo: sid)
          .snapshots()
          .listen((_) => controller.add(null), onError: (_) {}));
    }

    () async {
      shopId = await _getShopIdInternal();
      if (shopId != null) {
        listenCollections(shopId!);
      } else {
        // Retry after a short delay in case shopId not yet available
        await Future.delayed(const Duration(seconds: 2));
        shopId = await _getShopIdInternal();
        if (shopId != null) listenCollections(shopId!);
      }
    }();

    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
      await controller.close();
    };

    return controller.stream;
  }

  @override
  Stream<SaleModel?> watchLastSale(String shopId) {
    return _firestore
        .collection(AppConstants.salesCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      try {
        return SaleModel.fromJson(snap.docs.first.data());
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Stream<ReturnModel?> watchLastReturn(String shopId) {
    return _firestore
        .collection(AppConstants.returnsCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      try {
        return ReturnModel.fromJson(snap.docs.first.data());
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Stream<ExpenseModel?> watchLastExpense(String shopId) {
    return _watchLastExpenseDocs(shopId).map((docs) {
      for (final doc in docs) {
        try {
          final expense = ExpenseModel.fromJson(doc.data());
          if (expense.shopId == shopId) return expense;
        } catch (_) {
          // Corrupt doc: skipped instead of breaking the stream.
        }
      }
      return null;
    });
  }

  /// Latest expense docs — falls back to a local filter when the composite
  /// index for `where shopId + orderBy date` is missing.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _watchLastExpenseDocs(String shopId) async* {
    final col = _firestore.collection(AppConstants.expensesCollection);
    try {
      await for (final snap in col
          .where('shopId', isEqualTo: shopId)
          .orderBy('date', descending: true)
          .limit(5)
          .snapshots()) {
        yield snap.docs;
      }
    } catch (_) {
      await for (final snap
          in col.orderBy('date', descending: true).limit(20).snapshots()) {
        yield snap.docs;
      }
    }
  }
}
