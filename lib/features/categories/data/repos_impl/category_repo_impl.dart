import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repos/category_repo.dart';

class CategoryRepoImpl implements CategoryRepo {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  CategoryRepoImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<String?> _resolveShopId(String? provided) async {
    if (provided != null && provided.isNotEmpty) return provided;
    if (_uid == null) return null;
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  DocumentReference<Map<String, dynamic>> _shopDoc(String shopId) =>
      _firestore.collection('shops').doc(shopId);

  @override
  Stream<List<String>> watchCustomCategories(String shopId) async* {
    final resolved = await _resolveShopId(shopId);
    if (resolved == null || resolved.isEmpty) {
      yield [];
      return;
    }
    yield* _shopDoc(resolved).snapshots().map((snap) {
      if (!snap.exists) return <String>[];
      final data = snap.data();
      final raw = data?['customCategories'] as List<dynamic>?;
      if (raw == null) return <String>[];
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    });
  }

  @override
  Future<List<String>> getCustomCategories(String shopId) async {
    final resolved = await _resolveShopId(shopId);
    if (resolved == null || resolved.isEmpty) return [];
    final snap = await _shopDoc(resolved).get();
    if (!snap.exists) return [];
    final raw = snap.data()?['customCategories'] as List<dynamic>?;
    if (raw == null) return [];
    return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  }

  @override
  Future<void> addCategory(String shopId, String category) async {
    final resolved = await _resolveShopId(shopId);
    if (resolved == null || resolved.isEmpty) throw Exception('لم يتم العثور على المتجر');
    final trimmed = category.trim();
    if (trimmed.isEmpty) throw Exception('اسم القسم مطلوب');
    if (trimmed.length < 2) throw Exception('الاسم قصير جداً');
    final doc = _shopDoc(resolved);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final existingRaw = snap.exists ? (snap.data()?['customCategories'] as List<dynamic>?) : null;
      final existing = existingRaw?.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList() ?? <String>[];
      final lowerExisting = existing.map((e) => e.toLowerCase()).toSet();
      if (lowerExisting.contains(trimmed.toLowerCase())) {
        throw Exception('القسم موجود بالفعل');
      }
      // منع التكرار مع الأقسام الافتراضية سيتم فحصه في الـ Cubit (يحتاج businessType)
      final updated = [...existing, trimmed];
      if (snap.exists) {
        tx.update(doc, {'customCategories': updated, 'updatedAt': FieldValue.serverTimestamp()});
      } else {
        tx.set(doc, {'shopId': resolved, 'customCategories': updated, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
    });
  }

  @override
  Future<void> removeCategory(String shopId, String category) async {
    final resolved = await _resolveShopId(shopId);
    if (resolved == null || resolved.isEmpty) throw Exception('لم يتم العثور على المتجر');
    final doc = _shopDoc(resolved);
    final snap = await doc.get();
    if (!snap.exists) return;
    final raw = snap.data()?['customCategories'] as List<dynamic>?;
    if (raw == null) return;
    final list = raw.map((e) => e.toString()).toList();
    final updated = list.where((e) => e.trim().toLowerCase() != category.trim().toLowerCase()).toList();
    await doc.update({'customCategories': updated, 'updatedAt': FieldValue.serverTimestamp()});
  }
}
