import 'package:cloud_firestore/cloud_firestore.dart';

import '../repos/admin_search_repo.dart';

class AdminSearchRepoImpl implements AdminSearchRepo {
  AdminSearchRepoImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const int _pageSize = 50;

  @override
  Future<List<AdminSearchHit>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final hits = <AdminSearchHit>[];

    final shops =
        await _firestore.collection('shops').limit(_pageSize).get();
    for (final doc in shops.docs) {
      final data = doc.data();
      if (_matches(data['shopName'], q) ||
          _matches(data['ownerName'], q) ||
          _matches(data['phone'], q)) {
        hits.add(AdminSearchHit(
            'shop', data['shopName'] as String? ?? '-', doc.id));
      }
    }

    final products =
        await _firestore.collection('products').limit(_pageSize).get();
    for (final doc in products.docs) {
      final data = doc.data();
      if (_matches(data['name'], q)) {
        hits.add(AdminSearchHit(
            'product', data['name'] as String? ?? '-', doc.id));
      }
    }

    final requests = await _firestore
        .collection('subscription_requests')
        .limit(_pageSize)
        .get();
    for (final doc in requests.docs) {
      final data = doc.data();
      if (_matches(data['shopName'], q) ||
          _matches(data['phone'], q) ||
          _matches(data['ownerName'], q)) {
        hits.add(AdminSearchHit(
            'subscription_request', data['shopName'] as String? ?? '-', doc.id));
      }
    }

    return hits;
  }

  bool _matches(Object? value, String q) {
    return value != null && value.toString().toLowerCase().contains(q);
  }

  @override
  Future<Map<String, dynamic>?> fetchShop(String id) async {
    final snap = await _firestore.collection('shops').doc(id).get();
    return snap.exists ? snap.data() : null;
  }

  @override
  Future<Map<String, dynamic>?> fetchProduct(String id) async {
    final snap = await _firestore.collection('products').doc(id).get();
    return snap.exists ? snap.data() : null;
  }

  @override
  Future<Map<String, dynamic>?> fetchRequest(String id) async {
    final snap =
        await _firestore.collection('subscription_requests').doc(id).get();
    return snap.exists ? snap.data() : null;
  }
}
