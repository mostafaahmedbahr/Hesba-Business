import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/category_shop_context.dart';
import '../repos/category_repo.dart';

/// تنفيذ Firestore لعقد الأقسام.
class CategoryRepoImpl implements CategoryRepo {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CategoryRepoImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// id اليوزر الحالي.
  String? get _uid => _auth.currentUser?.uid;

  /// يحل shopId (الممرر أولاً ثم من اليوزر).
  Future<String?> _resolveShopId(String? provided) async {
    if (provided != null && provided.isNotEmpty) return provided;
    if (_uid == null) return null;
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  /// مرجع `shops/{shopId}`.
  DocumentReference<Map<String, dynamic>> _shopDoc(String shopId) =>
      _firestore.collection(AppConstants.shopsCollection).doc(shopId);

  @override
  Future<CategoryShopContext> getShopContext() async {
    if (_uid == null) return const CategoryShopContext(shopId: '');
    try {
      // يقرأ اليوزر: shopId + businessType.
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_uid)
          .get();
      final userData = userDoc.data();
      final shopId = userData?['shopId'] as String?;
      var businessType = userData?['businessType'] as String?;
      if (shopId == null || shopId.isEmpty) {
        return CategoryShopContext(shopId: '', businessType: businessType);
      }
      // لو النوع ناقص يجيبه من المحل.
      if (businessType == null) {
        final shopDoc = await _shopDoc(shopId).get();
        businessType = shopDoc.data()?['businessType'] as String?;
      }
      return CategoryShopContext(shopId: shopId, businessType: businessType);
    } catch (_) {
      return const CategoryShopContext(shopId: '');
    }
  }

  @override
  List<String> defaultCategoriesFor(String? businessType) {
    if (businessType != null &&
        AppConstants.productCategoriesByBusinessType.containsKey(businessType)) {
      return AppConstants.productCategoriesByBusinessType[businessType]!;
    }
    return AppConstants.defaultProductCategories;
  }

  @override
  Stream<List<String>> watchCustomCategories(String shopId) async* {
    final resolved = await _resolveShopId(shopId);
    if (resolved == null || resolved.isEmpty) {
      yield [];
      return;
    }
    yield* _shopDoc(resolved).snapshots().map((snap) {
      if (!snap.exists) return <String>[];
      final raw = snap.data()?['customCategories'] as List<dynamic>?;
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
    // transaction عشان جهازين مايضربوش بعض.
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final existingRaw = snap.exists ? (snap.data()?['customCategories'] as List<dynamic>?) : null;
      final existing = existingRaw?.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList() ?? <String>[];
      // يمنع التكرار.
      if (existing.map((e) => e.toLowerCase()).toSet().contains(trimmed.toLowerCase())) {
        throw Exception('القسم موجود بالفعل');
      }
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
    // يشيل المطابق (case-insensitive).
    final updated = raw.map((e) => e.toString()).where((e) => e.trim().toLowerCase() != category.trim().toLowerCase()).toList();
    await doc.update({'customCategories': updated, 'updatedAt': FieldValue.serverTimestamp()});
  }
}
