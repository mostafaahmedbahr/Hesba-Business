import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/expense_model.dart';
import '../repos/expenses_repo.dart';

class ExpensesRepoImpl implements ExpensesRepo {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ExpensesRepoImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String? get _uid => auth.currentUser?.uid;

  Future<String?> _resolveShopId(String? providedShopId) async {
    if (providedShopId != null && providedShopId.isNotEmpty) return providedShopId;
    if (_uid == null) return null;
    final doc = await firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  Future<String?> _resolveOwnerId(String? providedOwnerId) async {
    if (providedOwnerId != null && providedOwnerId.isNotEmpty) return providedOwnerId;
    return _uid;
  }

  @override
  Future<ExpenseModel> addExpense({
    required String ownerId,
    required String shopId,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    if (title.trim().isEmpty) throw Exception('عنوان المصروف مطلوب');
    if (amount <= 0) throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    if (category.isEmpty) throw Exception('اختر تصنيف المصروف');

    final resolvedShopId = await _resolveShopId(shopId);
    final resolvedOwnerId = await _resolveOwnerId(ownerId);

    if (resolvedShopId == null || resolvedShopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر');
    }
    if (resolvedOwnerId == null || resolvedOwnerId.isEmpty) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final ref = firestore.collection(AppConstants.expensesCollection).doc();
    final expense = ExpenseModel(
      expenseId: ref.id,
      ownerId: resolvedOwnerId,
      shopId: resolvedShopId,
      title: title.trim(),
      category: category,
      amount: amount,
      note: note.trim(),
      date: date,
      createdAt: DateTime.now(),
    );

    await ref.set(expense.toJson());
    return expense;
  }

@override
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    required String ownerId,
    required String shopId,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    if (title.trim().isEmpty) throw Exception('عنوان المصروف مطلوب');
    if (amount <= 0) throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    if (category.isEmpty) throw Exception('اختر تصنيف المصروف');

    final resolvedShopId = await _resolveShopId(shopId);
    final resolvedOwnerId = await _resolveOwnerId(ownerId);

    if (resolvedShopId == null || resolvedShopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر');
    }
    if (resolvedOwnerId == null || resolvedOwnerId.isEmpty) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final docRef = firestore.collection(AppConstants.expensesCollection).doc(expenseId);
    final existingSnap = await docRef.get();
    final existingData = existingSnap.data();
    if (!existingSnap.exists || existingData == null) {
      throw Exception('المصروف غير موجود');
    }
    // Ownership check: never touch another shop's document by ID.
    if (existingData['shopId'] != resolvedShopId || existingData['ownerId'] != resolvedOwnerId) {
      throw Exception('غير مصرح بتعديل هذا المصروف');
    }
    final existingCreatedAt = (existingData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final updated = ExpenseModel(
      expenseId: expenseId,
      ownerId: resolvedOwnerId,
      shopId: resolvedShopId,
      title: title.trim(),
      category: category,
      amount: amount,
      note: note.trim(),
      date: date,
      createdAt: existingCreatedAt,
    );

    await docRef.update(updated.toJson());
    return updated;
  }

  @override
  Future<List<ExpenseModel>> getExpenses({required String shopId}) async {
    final resolvedShopId = await _resolveShopId(shopId);
    // اعرض الكل لو الـ shopId فاضي — يضمن ظهور البيانات حتى لو الحقل مختلف
    Query<Map<String, dynamic>> query = firestore.collection(AppConstants.expensesCollection);
    try {
      if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
        query = query.where('shopId', isEqualTo: resolvedShopId);
      } else if (_uid != null) {
        query = query.where('ownerId', isEqualTo: _uid);
      }
      final snap = await query.orderBy('createdAt', descending: true).limit(500).get();
      return snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList();
    } catch (_) {
      // fallback بدون index — حمّل الكل وفلتر محلياً (للمالك فقط، أبداً الكل).
      if (_uid == null) throw Exception('يجب تسجيل الدخول أولاً');
      final snap = await firestore.collection(AppConstants.expensesCollection).orderBy('createdAt', descending: true).limit(500).get();
      final all = snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList();
      if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
        return all.where((e) => e.shopId == resolvedShopId || e.shopId.isEmpty).toList();
      }
      return all.where((e) => e.ownerId == _uid || e.shopId.isEmpty).toList();
    }
  }

  /// يحول الـ snapshot لقائمة مع فلترة محلية حسب المحل.
  /// لا تعرض أبداً بيانات محل آخر: عند غياب التطابق ترجع قائمة فارغة
  /// (مستندات shopId فارغ القديمة تُعرض لصاحبها فقط كتوافق).
  List<ExpenseModel> _toFiltered(
    QuerySnapshot<Map<String, dynamic>> snap,
    String? resolvedShopId,
  ) {
    final all = snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList();
    if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
      return all.where((e) => e.shopId == resolvedShopId || e.shopId.isEmpty).toList();
    }
    if (_uid != null) {
      return all.where((e) => e.ownerId == _uid || e.shopId.isEmpty).toList();
    }
    return const [];
  }

  @override
  Stream<List<ExpenseModel>> watchExpenses({required String shopId}) async* {
    final resolvedShopId = await _resolveShopId(shopId);
    Query<Map<String, dynamic>> query = firestore.collection(AppConstants.expensesCollection);
    if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
      query = query.where('shopId', isEqualTo: resolvedShopId);
    } else if (_uid != null) {
      query = query.where('ownerId', isEqualTo: _uid);
    }
    try {
      // المحاولة الأساسية (تحتاج composite index).
      await for (final snap
          in query.orderBy('createdAt', descending: true).limit(500).snapshots()) {
        yield _toFiltered(snap, resolvedShopId);
      }
    } catch (_) {
      // الـ index ناقص: fallback لقراءة بدون where + فلترة محلية.
      await for (final snap in firestore
          .collection(AppConstants.expensesCollection)
          .orderBy('createdAt', descending: true)
          .limit(500)
          .snapshots()) {
        yield _toFiltered(snap, resolvedShopId);
      }
    }
  }

  @override
  Future<void> deleteExpense({required String expenseId, required String shopId}) async {
    final resolvedShopId = await _resolveShopId(shopId);
    if (resolvedShopId == null) throw Exception('لم يتم العثور على المتجر');
    final docRef = firestore.collection(AppConstants.expensesCollection).doc(expenseId);
    final snap = await docRef.get();
    final data = snap.data();
    if (!snap.exists || data == null) throw Exception('المصروف غير موجود');
    if (data['shopId'] != resolvedShopId || (data['ownerId'] as String?) != _uid) {
      throw Exception('غير مصرح بحذف هذا المصروف');
    }
    await docRef.delete();
  }
}
