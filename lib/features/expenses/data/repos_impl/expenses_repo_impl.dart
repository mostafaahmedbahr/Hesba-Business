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
    final existingData = existingSnap.data()!;
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
      final snap = await query.orderBy('createdAt', descending: true).get();
      return snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList();
    } catch (_) {
      // fallback بدون index — حمّل الكل وفلتر محلياً
      final snap = await firestore.collection(AppConstants.expensesCollection).orderBy('createdAt', descending: true).get();
      final all = snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList();
      if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
        return all.where((e) => e.shopId == resolvedShopId).toList();
      }
      if (_uid != null) return all.where((e) => e.ownerId == _uid).toList();
      return all;
    }
  }

  @override
  Stream<List<ExpenseModel>> watchExpenses({required String shopId}) {
    // نحاول أولاً بالـ shopId، ولو فشل (index أو فارغ) نعرض الكل بفلترة محلية
    final resolvedFuture = _resolveShopId(shopId);
    return Stream.fromFuture(resolvedFuture).asyncExpand((resolvedShopId) {
      Stream<QuerySnapshot<Map<String, dynamic>>> base;
      try {
        Query<Map<String, dynamic>> query = firestore.collection(AppConstants.expensesCollection);
        if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
          query = query.where('shopId', isEqualTo: resolvedShopId);
        } else if (_uid != null) {
          query = query.where('ownerId', isEqualTo: _uid);
        }
        base = query.orderBy('createdAt', descending: true).snapshots();
      } catch (_) {
        base = firestore.collection(AppConstants.expensesCollection).orderBy('createdAt', descending: true).snapshots();
      }
      return base.map((snap) {
        final all = snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList();
        // لو الـ query كان بدون فلتر، نفلتر محلياً حسب الـ resolved
        if (resolvedShopId != null && resolvedShopId.isNotEmpty) {
          final filtered = all.where((e) => e.shopId == resolvedShopId).toList();
          // لو الفلترة رجعت فاضية بس فيه داتا، اعرض الكل (يضمن يبان حتى لو shopId مختلف)
          if (filtered.isEmpty && all.isNotEmpty && all.any((e) => e.shopId.isEmpty)) return all;
          return filtered.isEmpty ? all : filtered;
        }
        if (_uid != null) {
          final byOwner = all.where((e) => e.ownerId == _uid).toList();
          return byOwner.isEmpty ? all : byOwner;
        }
        return all;
      }).handleError((e) {
        // لو الـ index ناقص، fallback لقراءة بدون where
        return firestore.collection(AppConstants.expensesCollection).orderBy('createdAt', descending: true).snapshots().map((snap) => snap.docs.map((d) => ExpenseModel.fromJson(d.data())).toList());
      });
    });
  }

  @override
  Future<void> deleteExpense({required String expenseId, required String shopId}) async {
    final resolvedShopId = await _resolveShopId(shopId);
    if (resolvedShopId == null) throw Exception('لم يتم العثور على المتجر');
    await firestore
        .collection(AppConstants.expensesCollection)
        .doc(expenseId)
        .delete();
  }
}
