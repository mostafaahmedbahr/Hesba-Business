import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/debt_model.dart';
import '../models/payment_model.dart';
import '../models/person_model.dart';
import '../repos/accounts_repo.dart';

/// تنفيذ ميزة الحسابات على Firestore.
///
/// سياسة العزل (مطابقة لـ products/sales/suppliers):
/// - القراءة: `where('shopId' == myShopId)` على الخادم + تحقق محلي إضافي.
/// - الكتابة: تحقق shopId/ownerId قبل أي تعديل، والدفعة تُنفذ داخل
///   transaction ذرّية حتى لا يضيع تحديث `paidAmount`.
class AccountsRepoImpl implements AccountsRepo {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// أقصى عدد سجلات يُحمَّل في جلسة واحدة (نفس حد الموردين).
  static const int _pageLimit = 500;

  AccountsRepoImpl({required this._auth, required this._firestore});

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _persons =>
      _firestore.collection(AppConstants.personsCollection);

  CollectionReference<Map<String, dynamic>> get _debts =>
      _firestore.collection(AppConstants.debtsCollection);

  Future<String?> _getShopId() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  Future<String> _requireShop() async {
    if (_uid == null) {
      throw Exception('يجب تسجيل الدخول أولًا');
    }
    final shopId = await _getShopId();
    if (shopId == null || shopId.isEmpty) {
      throw Exception('لا يوجد محل مرتبط بهذا الحساب');
    }
    return shopId;
  }

  List<DebtModel> _debtsSafe(
    QuerySnapshot<Map<String, dynamic>> snap,
    String shopId,
  ) {
    return snap.docs
        .map((d) => DebtModel.fromJson(d.data(), docId: d.id))
        .where((d) => d.shopId == shopId && d.ownerId.isNotEmpty)
        .toList();
  }

  List<PersonModel> _personsSafe(
    QuerySnapshot<Map<String, dynamic>> snap,
    String shopId,
  ) {
    return snap.docs
        .map((d) => PersonModel.fromJson(d.data(), docId: d.id))
        .where((p) => p.shopId == shopId && p.ownerId.isNotEmpty)
        .toList();
  }

  // ─────────────────────────── القراءة ───────────────────────────

  @override
  Stream<List<DebtModel>> watchDebts() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return () async* {
      final shopId = await _getShopId();
      if (shopId == null || shopId.isEmpty) {
        yield const <DebtModel>[];
        return;
      }
      await for (final snap in _debts
          .where('shopId', isEqualTo: shopId)
          .orderBy('createdAt', descending: true)
          .limit(_pageLimit)
          .snapshots()) {
        yield _debtsSafe(snap, shopId);
      }
    }();
  }

  @override
  Stream<List<PersonModel>> watchPersons() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return () async* {
      final shopId = await _getShopId();
      if (shopId == null || shopId.isEmpty) {
        yield const <PersonModel>[];
        return;
      }
      await for (final snap in _persons
          .where('shopId', isEqualTo: shopId)
          .orderBy('createdAt', descending: true)
          .limit(_pageLimit)
          .snapshots()) {
        yield _personsSafe(snap, shopId);
      }
    }();
  }

  @override
  Future<List<PersonModel>> searchPersons(String query) async {
    final q = query.trim();
    final shopId = await _requireShop();
    final snap = await _persons
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(_pageLimit)
        .get();
    final all = _personsSafe(snap, shopId);
    if (q.isEmpty) return all;
    final qLower = q.toLowerCase();
    final qPhone = PersonModel.normalizePhone(q);
    return all.where((p) {
      if (p.name.toLowerCase().contains(qLower)) return true;
      if (qPhone.isNotEmpty && p.normalizedPhone.contains(qPhone)) return true;
      return false;
    }).toList();
  }

  @override
  Stream<DebtModel?> watchDebt(String debtId) {
    if (debtId.isEmpty) return Stream.value(null);
    return _debts.doc(debtId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return DebtModel.fromJson(data, docId: snap.id);
    });
  }

  @override
  Stream<List<PaymentModel>> watchPayments(String debtId) {
    if (debtId.isEmpty) return const Stream.empty();
    return _debts
        .doc(debtId)
        .collection(AppConstants.debtPaymentsSubCollection)
        .orderBy('createdAt', descending: true)
        .limit(_pageLimit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PaymentModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  // ─────────────────────────── الكتابة ───────────────────────────

  @override
  Future<DebtModel> addDebt({
    required String name,
    required String phone,
    required String partyType,
    required String direction,
    required double amount,
    String note = '',
  }) async {
    final shopId = await _requireShop();
    final uid = _uid!;
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    if (cleanName.isEmpty) throw Exception('الاسم مطلوب');
    if (cleanPhone.isEmpty) throw Exception('رقم الهاتف مطلوب');
    _assertPhoneShape(cleanPhone);
    if (!amount.isFinite || amount <= 0) {
      throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    }
    if (partyType != DebtParty.customer && partyType != DebtParty.supplier) {
      throw Exception('نوع الطرف غير صحيح');
    }
    // العملاء دائمًا «ليّا» — لا يمكن قلب الاتجاه إلا للموردين.
    final cleanDirection = partyType == DebtParty.customer
        ? DebtDirection.receivable
        : (direction == DebtDirection.payable
            ? DebtDirection.payable
            : DebtDirection.receivable);

    // منع التكرار: نفس الرقم الموحّد داخل نفس المحل = نفس الشخص.
    // ملاحظة: يُنشأ الشخص أولًا في كتابة مستقلة، ثم تُنشأ الذمة —
    // لأن قواعد Firestore تُقيَّم ضد الحالة قبل العملية، فتحتاج
    // الذمة أن تجد مستند الشخص موجودًا فعلًا.
    final existing = await _findPersonByPhone(shopId, cleanPhone);
    final String personId;
    final String personName;
    if (existing != null) {
      personId = existing.id;
      personName = cleanName; // لقطة الاسم من الإدخال الحالي
      final mergedType = PersonModel.mergeType(existing.type, partyType);
      if (mergedType != existing.type) {
        await _persons.doc(existing.id).update({
          'type': mergedType,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      final ref = _persons.doc();
      personId = ref.id;
      personName = cleanName;
      await ref.set({
        'id': ref.id,
        'ownerId': uid,
        'shopId': shopId,
        'name': cleanName,
        'phone': cleanPhone,
        'type': partyType,
        'normalizedPhone': PersonModel.normalizePhone(cleanPhone),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final debtRef = _debts.doc();
    final debt = DebtModel(
      id: debtRef.id,
      ownerId: uid,
      shopId: shopId,
      personId: personId,
      personName: personName,
      personPhone: cleanPhone,
      partyType: partyType,
      direction: cleanDirection,
      amount: amount,
      paidAmount: 0,
      note: note.trim(),
    );
    await debtRef.set({
      ...debt.toJson(),
      'id': debtRef.id,
      'ownerId': uid,
      'shopId': shopId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return debt;
  }

  @override
  Future<void> addPayment({
    required String debtId,
    required double amount,
    String note = '',
  }) async {
    if (debtId.isEmpty) throw Exception('الحساب غير موجود');
    if (!amount.isFinite || amount <= 0) {
      throw Exception('مبلغ الدفعة يجب أن يكون أكبر من صفر');
    }
    final shopId = await _requireShop();
    final uid = _uid!;
    final debtRef = _debts.doc(debtId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(debtRef);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw Exception('الحساب غير موجود');
      }
      if (data['shopId'] != shopId) {
        throw Exception('لا تملك صلاحية على هذا الحساب');
      }
      final total = (data['amount'] is num)
          ? (data['amount'] as num).toDouble()
          : 0.0;
      final paid = (data['paidAmount'] is num)
          ? (data['paidAmount'] as num).toDouble()
          : 0.0;
      final remaining = total - paid;
      // سماحية كسرية بسيطة ضد فروقات الفاصلة العائمة.
      if (amount > remaining + 0.0001) {
        throw Exception('الدفعة أكبر من المتبقي (${remaining.toStringAsFixed(2)})');
      }
      final paymentRef = debtRef
          .collection(AppConstants.debtPaymentsSubCollection)
          .doc();
      txn.set(paymentRef, {
        'id': paymentRef.id,
        'ownerId': uid,
        'shopId': shopId,
        'amount': amount,
        'note': note.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      txn.update(debtRef, {
        'paidAmount': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ─────────────────────────── خصوصي ───────────────────────────

  /// البحث عن شخص بنفس الرقم الموحّد داخل نفس المحل.
  Future<PersonModel?> _findPersonByPhone(String shopId, String phone) async {
    final target = PersonModel.normalizePhone(phone);
    if (target.isEmpty) return null;
    final snap = await _persons
        .where('shopId', isEqualTo: shopId)
        .limit(_pageLimit)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['shopId'] != shopId) continue;
      // النظام القديم قد لا يحتوي normalizedPhone — نحسبها عند القراءة.
      final stored = data['normalizedPhone'];
      final other = stored is String && stored.isNotEmpty
          ? stored
          : PersonModel.normalizePhone('${data['phone'] ?? ''}');
      if (other.isNotEmpty && other == target) {
        return PersonModel.fromJson(data, docId: doc.id);
      }
    }
    return null;
  }

  /// صيغة الرقم: 7-15 رقماً (اختيارياً + في الأول).
  void _assertPhoneShape(String phone) {
    final normalized = PersonModel.normalizePhone(phone);
    final digits = normalized.replaceAll('+', '');
    final valid = digits.isNotEmpty &&
        digits.length >= 7 &&
        digits.length <= 15 &&
        RegExp(r'^[0-9]+$').hasMatch(digits);
    if (!valid) throw Exception('رقم الهاتف غير صحيح');
  }
}
