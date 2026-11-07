import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/log_util.dart';
import '../../../../core/models/product.dart';
import '../models/supplier_model.dart';
import '../repos/suppliers_repo.dart';

/// تنفيذ ميزة الموردين على Firestore.
///
/// سياسة العزل (مطابقة لسياسة products/sales/expenses):
/// - القراءة: `where('shopId' == myShopId)` على الخادم + تحقق محلي إضافي
///   من `shopId`، فلا يظهر أبداً مورد لمحل آخر.
/// - الكتابة: تحقق `shopId == myShopId && ownerId == uid` قبل أي تعديل/حذف
///   (نفس قاعدة products: صاحب المستند أو الأدمن فقط).
class SuppliersRepoImpl implements SuppliersRepo {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// أقصى عدد موردي/منتجات محل واحد يُحمَّل في جلسة واحدة (نفس حد products).
  static const int _pageLimit = 500;

  /// أقصى عدد عمليات التعديل في دفعة واحدة (حد Firestore 500).
  static const int _batchLimit = 400;

  SuppliersRepoImpl({required this._auth, required this._firestore});

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _suppliers =>
      _firestore.collection(AppConstants.suppliersCollection);

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(AppConstants.productsCollection);

  Future<String?> _getShopId() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  /// يتأكد إن المعرّفين متاحين، وإلا يرمي رسالة مفهومة.
  Future<String> _requireShop() async {
    if (_uid == null) throw Exception('supplierErrNotSignedIn');
    final shopId = await _getShopId();
    if (shopId == null || shopId.isEmpty) throw Exception('supplierErrNoShop');
    return shopId;
  }

  /// قراءة مورد ضمن حدود المحل الحالي (لأي مستخدم داخل المحل).
  Future<SupplierModel> _loadForRead(String supplierId) async {
    final shopId = await _requireShop();
    final snap = await _suppliers.doc(supplierId).get();
    final data = snap.data();
    if (!snap.exists || data == null) throw Exception('supplierErrNotFound');
    if (data['shopId'] != shopId) throw Exception('supplierErrNotAuthorized');
    return SupplierModel.fromJson(data, docId: snap.id);
  }

  /// تحميل مورد للتعديل/الحذف: داخل المحل الحالي **و** من صنعه.
  Future<SupplierModel> _loadForWrite(String supplierId) async {
    final uid = _uid;
    final shopId = await _requireShop();
    final snap = await _suppliers.doc(supplierId).get();
    final data = snap.data();
    if (!snap.exists || data == null) throw Exception('supplierErrNotFound');
    if (data['shopId'] != shopId || (data['ownerId'] as String?) != uid) {
      throw Exception('supplierErrNotAuthorized');
    }
    return SupplierModel.fromJson(data, docId: snap.id);
  }

  /// تحويل snapshot لقائمة مع فلترة محلية صارمة على حدود المحل —
  /// طبقة أمان ثانية فوق فلتر الخادم.
  List<SupplierModel> _safeList(
    QuerySnapshot<Map<String, dynamic>> snap,
    String shopId,
  ) {
    return snap.docs
        .map((d) => SupplierModel.fromJson(d.data(), docId: d.id))
        .where((s) => s.shopId == shopId && s.ownerId.isNotEmpty)
        .toList();
  }

  // ─────────────────────────── القراءة ───────────────────────────

  @override
  Future<String?> getShopId() => _getShopId();

  @override
  Stream<List<SupplierModel>> watchSuppliers() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return () async* {
      final shopId = await _getShopId();
      if (shopId == null || shopId.isEmpty) {
        yield const <SupplierModel>[];
        return;
      }
      await for (final snap
          in _suppliers
              .where('shopId', isEqualTo: shopId)
              .orderBy('createdAt', descending: true)
              .limit(_pageLimit)
              .snapshots()) {
        yield _safeList(snap, shopId);
      }
    }();
  }

  @override
  Future<List<SupplierModel>> getSuppliers() async {
    final shopId = await _requireShop();
    final snap = await _suppliers
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(_pageLimit)
        .get();
    return _safeList(snap, shopId);
  }

  @override
  Future<SupplierModel?> getSupplierById(String supplierId) async {
    if (supplierId.isEmpty) return null;
    try {
      return await _loadForRead(supplierId);
    } on Exception {
      // مورد محذوف أو لمحل آخر: يرجع null بدل ما يكسر واجهة الاستدعاء.
      return null;
    }
  }

  @override
  Future<List<SupplierModel>> searchSuppliers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getSuppliers();
    final suppliers = await getSuppliers();
    final qLower = q.toLowerCase();
    // الرقم يُقارن بعد التوحيد حتى يلاقي "0100 111" "0100111".
    final qPhone = SupplierModel.normalizePhone(q);
    return suppliers.where((s) {
      if (s.name.toLowerCase().contains(qLower)) return true;
      if (s.companyName.toLowerCase().contains(qLower)) return true;
      if (qPhone.isNotEmpty && s.normalizedPhone.contains(qPhone)) return true;
      return false;
    }).toList();
  }

  // ─────────────────────────── الكتابة ───────────────────────────

  @override
  Future<SupplierModel> addSupplier({
    required String name,
    required String phone,
    String companyName = '',
    String secondaryPhone = '',
    String email = '',
    String address = '',
    String city = '',
    String notes = '',
  }) async {
    final shopId = await _requireShop();
    final uid = _uid!;
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    if (cleanName.isEmpty) throw Exception('supplierErrNameRequired');
    if (cleanPhone.isEmpty) throw Exception('supplierErrPhoneRequired');
    _assertPhoneShape(cleanPhone);
    await _assertPhoneIsFree(shopId, cleanPhone);

    final ref = _suppliers.doc();
    final now = FieldValue.serverTimestamp();
    final supplier = SupplierModel(
      id: ref.id,
      ownerId: uid,
      shopId: shopId,
      name: cleanName,
      phone: cleanPhone,
      companyName: companyName.trim(),
      secondaryPhone: secondaryPhone.trim(),
      email: email.trim(),
      address: address.trim(),
      city: city.trim(),
      notes: notes.trim(),
    );

    // الحقول القابلة للتعديل + معرّفات الملكية + توقيت الخادم.
    await ref.set({
      ...supplier.toJson(),
      'id': ref.id,
      'ownerId': uid,
      'shopId': shopId,
      'createdAt': now,
      'updatedAt': now,
    });
    return supplier;
  }

  @override
  Future<SupplierModel> updateSupplier({
    required String supplierId,
    String? name,
    String? phone,
    String? companyName,
    String? secondaryPhone,
    String? email,
    String? address,
    String? city,
    String? notes,
  }) async {
    if (supplierId.isEmpty) throw Exception('supplierErrNotFound');
    final existing = await _loadForWrite(supplierId);

    final fields = <String, dynamic>{};
    void put(String key, String? value) {
      if (value == null) return; // null = اترك الحقل كما هو.
      fields[key] = value.trim();
    }

    put('name', name);
    put('phone', phone);
    put('companyName', companyName);
    put('secondaryPhone', secondaryPhone);
    put('email', email);
    put('address', address);
    put('city', city);
    put('notes', notes);
    if (fields.isEmpty) return existing;

    final nextName = (fields['name'] as String?) ?? existing.name;
    final nextPhone = (fields['phone'] as String?) ?? existing.phone;
    if (nextName.trim().isEmpty) throw Exception('supplierErrNameRequired');
    if (nextPhone.trim().isEmpty) throw Exception('supplierErrPhoneRequired');
    _assertPhoneShape(nextPhone);
    if (fields.containsKey('phone')) {
      await _assertPhoneIsFree(
        existing.shopId,
        nextPhone,
        ignoreSupplierId: supplierId,
      );
    }

    await _suppliers.doc(supplierId).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // لقطة الاسم في المنتجات: نحدّثها عند تغيير الاسم حتى لا يظل
    // المنتج يعرض اسماً قديماً. أفضل جهد (best-effort) — عند الفشل
    // يعيد نموذج المنتج قراءة اسم المورد الحيّ عند الحفظ.
    if (fields.containsKey('name') && nextName.trim() != existing.name.trim()) {
      await _syncLinkedProductNames(
        existing.shopId,
        supplierId,
        nextName.trim(),
      );
    }

    return SupplierModel(
      id: existing.id,
      ownerId: existing.ownerId,
      shopId: existing.shopId,
      name: nextName.trim(),
      phone: nextPhone.trim(),
      companyName: (fields['companyName'] as String?) ?? existing.companyName,
      secondaryPhone:
          (fields['secondaryPhone'] as String?) ?? existing.secondaryPhone,
      email: (fields['email'] as String?) ?? existing.email,
      address: (fields['address'] as String?) ?? existing.address,
      city: (fields['city'] as String?) ?? existing.city,
      notes: (fields['notes'] as String?) ?? existing.notes,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteSupplier(String supplierId) async {
    if (supplierId.isEmpty) return;
    final existing = await _loadForWrite(supplierId);

    final linked = await _products
        .where('shopId', isEqualTo: existing.shopId)
        .where('supplierId', isEqualTo: supplierId)
        .limit(1)
        .get();
    if (linked.docs.isNotEmpty) {
      throw Exception('supplierErrLinkedProducts');
    }
    await _suppliers.doc(supplierId).delete();
  }

  // ─────────────────────── المنتجات المرتبطة ───────────────────────

  @override
  Stream<Map<String, int>> watchLinkedProductCounts() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return () async* {
      final shopId = await _getShopId();
      if (shopId == null || shopId.isEmpty) {
        yield const <String, int>{};
        return;
      }
      await for (final snap
          in _products
              .where('shopId', isEqualTo: shopId)
              .limit(_pageLimit)
              .snapshots()) {
        final counts = <String, int>{};
        for (final doc in snap.docs) {
          final data = doc.data();
          if (data['shopId'] != shopId) continue;
          final supplierId = data['supplierId'] as String?;
          if (supplierId == null || supplierId.isEmpty) continue;
          counts[supplierId] = (counts[supplierId] ?? 0) + 1;
        }
        yield counts;
      }
    }();
  }

  @override
  Future<List<Product>> getLinkedProducts(String supplierId) async {
    if (supplierId.isEmpty) return const [];
    final shopId = await _requireShop();
    final snap = await _products
        .where('shopId', isEqualTo: shopId)
        .where('supplierId', isEqualTo: supplierId)
        .limit(_pageLimit)
        .get();
    final products = snap.docs
        .map((d) => Product.fromJson(d.data(), docId: d.id))
        .where((p) => p.shopId == shopId && p.supplierId == supplierId)
        .toList();
    products.sort((a, b) {
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });
    return products;
  }

  /// تحديث لقطة `supplierName` في كل المنتجات المرتبطة بعد تغيير الاسم.
  ///
  /// مقسّم لدفعات لتجاوز حد الـ 500 عملية في دفعة واحدة. أي فشل
  /// (اشتراك منتهٍ/صلاحيات) يُسجَّل ويُترك — لا يُفشل تعديل المورد.
  Future<void> _syncLinkedProductNames(
    String shopId,
    String supplierId,
    String newName,
  ) async {
    try {
      final snap = await _products
          .where('shopId', isEqualTo: shopId)
          .where('supplierId', isEqualTo: supplierId)
          .limit(_pageLimit)
          .get();
      if (snap.docs.isEmpty) return;
      var batch = _firestore.batch();
      var pending = 0;
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'supplierName': newName});
        pending++;
        if (pending >= _batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          pending = 0;
        }
      }
      if (pending > 0) await batch.commit();
    } catch (e) {
      logWarning('[SuppliersRepo] supplierName sync failed: $e');
    }
  }

  // ─────────────────────────── خصوصي ───────────────────────────

  /// صيغة الرقم: 7-15 رقماً بعد التوحيد — أرقام فقط (اختيارياً بعلامة
  /// "+" في الأول)، فلا تمر نصوص like "not-a-phone" حتى لا ترتد الكتابة
  /// من قواعد الأمان في Firestore بعد قبولها هنا.
  void _assertPhoneShape(String phone) {
    final normalized = SupplierModel.normalizePhone(phone);
    final digits = normalized.replaceAll('+', '');
    final valid =
        digits.isNotEmpty &&
        digits.length >= 7 &&
        digits.length <= 15 &&
        RegExp(r'^[0-9]+$').hasMatch(digits);
    if (!valid) throw Exception('supplierErrPhoneInvalid');
  }

  /// منع التكرار: رقم موحّد واحد فقط لكل مورد داخل نفس المحل.
  Future<void> _assertPhoneIsFree(
    String shopId,
    String phone, {
    String? ignoreSupplierId,
  }) async {
    final target = SupplierModel.normalizePhone(phone);
    if (target.isEmpty) return;
    final snap = await _suppliers
        .where('shopId', isEqualTo: shopId)
        .limit(_pageLimit)
        .get();
    for (final doc in snap.docs) {
      if (ignoreSupplierId != null && doc.id == ignoreSupplierId) continue;
      final data = doc.data();
      if (data['shopId'] != shopId) continue;
      final other = SupplierModel.normalizePhone('${data['phone'] ?? ''}');
      if (other.isNotEmpty && other == target) {
        throw Exception('supplierErrDuplicatePhone');
      }
    }
  }
}
