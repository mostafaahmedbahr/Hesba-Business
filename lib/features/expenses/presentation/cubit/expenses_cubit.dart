import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/app_events.dart';
import '../../data/models/expense_model.dart';
import '../../data/repos/expenses_repo.dart';
import 'expenses_state.dart';

class ExpensesCubit extends Cubit<ExpensesState> {
  final ExpensesRepo expensesRepo;
  final FirebaseAuth? _auth;
  StreamSubscription<List<ExpenseModel>>? _expensesSubscription;
  StreamSubscription<AppEvent>? _eventSub;
  String? _lastShopId;

  ExpensesCubit({required this.expensesRepo, FirebaseAuth? this._auth})
      : super(const ExpensesState()) {
    // أي إضافة/تعديل/حذف من أي Cubit تاني يحدّث القائمة فوراً
    _eventSub = AppEvents.instance.stream.listen((event) {
      if (event.type == AppEventType.expenseCreated ||
          event.type == AppEventType.expenseUpdated ||
          event.type == AppEventType.expenseDeleted) {
        if (_lastShopId != null) loadExpenses(shopId: _lastShopId!);
      }
    });
  }

  void reset() {
    _expensesSubscription?.cancel();
    _expensesSubscription = null;
    emit(const ExpensesState());
  }

  Future<String?> _resolveShopId(String? providedShopId) async {
    if (providedShopId != null && providedShopId.isNotEmpty) return providedShopId;
    if (_auth == null) return null;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  Future<void> loadExpenses({required String shopId}) async {
    _lastShopId = shopId;
    _expensesSubscription?.cancel();
    _expensesSubscription = null;
    emit(state.copyWith(status: ExpensesStatus.loading, errorMessage: null));
    final resolvedShopId = await _resolveShopId(shopId);
    // حتى لو الـ shopId فاضي، اعرض الكل (repo بيعمل fallback)
    final effectiveShopId = resolvedShopId ?? shopId;
    _expensesSubscription = expensesRepo.watchExpenses(shopId: effectiveShopId).listen(
      (expenses) {
        final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
        emit(state.copyWith(
          status: ExpensesStatus.success,
          expenses: expenses,
          totalAmount: total,
        ));
      },
      onError: (e) {
        final msg = e.toString().replaceAll('Exception: ', '');
        emit(state.copyWith(status: ExpensesStatus.error, errorMessage: msg));
      },
    );
  }

  Future<void> addExpense({
    required String ownerId,
    required String shopId,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'عنوان المصروف مطلوب'));
      return;
    }
    if (amount <= 0) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'المبلغ يجب أن يكون أكبر من صفر'));
      return;
    }
    if (category.isEmpty) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'اختر تصنيف المصروف'));
      return;
    }

    emit(state.copyWith(status: ExpensesStatus.loading, errorMessage: null));
    try {
      final expense = await expensesRepo.addExpense(
        ownerId: ownerId,
        shopId: shopId,
        title: title,
        category: category,
        amount: amount,
        note: note,
        date: date,
      );
      AppEvents.instance.expenseCreated();
      AppEvents.instance.productChanged();
      emit(state.copyWith(status: ExpensesStatus.success, addedExpense: expense, errorMessage: null));
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: msg));
    }
  }

  Future<void> updateExpense({
    required String expenseId,
    required String ownerId,
    required String shopId,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'عنوان المصروف مطلوب'));
      return;
    }
    if (amount <= 0) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'المبلغ يجب أن يكون أكبر من صفر'));
      return;
    }
    if (category.isEmpty) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'اختر تصنيف المصروف'));
      return;
    }

    emit(state.copyWith(status: ExpensesStatus.loading, errorMessage: null));
    try {
      final expense = await expensesRepo.updateExpense(
        expenseId: expenseId,
        ownerId: ownerId,
        shopId: shopId,
        title: title,
        category: category,
        amount: amount,
        note: note,
        date: date,
      );
      AppEvents.instance.expenseUpdated();
      AppEvents.instance.productChanged();
      emit(state.copyWith(status: ExpensesStatus.success, addedExpense: expense, errorMessage: null));
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: msg));
    }
  }

  Future<void> deleteExpense({required String expenseId, required String shopId}) async {
    try {
      await expensesRepo.deleteExpense(expenseId: expenseId, shopId: shopId);
      AppEvents.instance.expenseDeleted();
      AppEvents.instance.productChanged();
      emit(state.copyWith(status: ExpensesStatus.success));
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: msg));
    }
  }

  @override
  Future<void> close() {
    _expensesSubscription?.cancel();
    _eventSub?.cancel();
    return super.close();
  }
}
