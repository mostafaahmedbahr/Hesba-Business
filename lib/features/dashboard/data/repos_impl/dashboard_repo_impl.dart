import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Future<String?> _getShopId() async {
    if (_uid == null) return null;
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  @override
  Future<double> getTodaySalesTotal() async {
    final shopId = await _getShopId();
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
    final shopId = await _getShopId();
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
  Future<double> getTodayExpensesTotal() async {
    final shopId = await _getShopId();
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
    final shopId = await _getShopId();
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
    final shopId = await _getShopId();
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
  Stream<String?> watchShopName() {
    if (_uid == null) return Stream.value(null);
    return _firestore.collection('users').doc(_uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return snap.data()?['shopName'] as String?;
    });
  }
}
