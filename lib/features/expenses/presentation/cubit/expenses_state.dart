import 'package:equatable/equatable.dart';

import '../../data/models/expense_model.dart';

enum ExpensesStatus { initial, loading, success, error }

class ExpensesState extends Equatable {
  final ExpensesStatus status;
  final List<ExpenseModel> expenses;
  final ExpenseModel? addedExpense;
  final String? errorMessage;
  final double totalAmount;
  final String searchQuery; // نص البحث.
  final String categoryFilter; // فلتر التصنيف (الكل + التصنيفات).

  const ExpensesState({
    this.status = ExpensesStatus.initial,
    this.expenses = const [],
    this.addedExpense,
    this.errorMessage,
    this.totalAmount = 0,
    this.searchQuery = '',
    this.categoryFilter = 'الكل',
  });

  /// المصروفات بعد البحث + الفلتر.
  List<ExpenseModel> get filtered {
    final q = searchQuery.trim().toLowerCase();
    return expenses.where((e) {
      final matchesSearch = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.note.toLowerCase().contains(q);
      final matchesCat = categoryFilter == 'الكل' || e.category == categoryFilter;
      return matchesSearch && matchesCat;
    }).toList();
  }

  /// مصروفات النهاردة.
  List<ExpenseModel> get todayList {
    final now = DateTime.now();
    return expenses.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).toList();
  }

  /// إجمالي النهاردة.
  double get todayTotal => todayList.fold<double>(0, (s, e) => s + e.amount);

  /// التصنيفات الموجودة (للفلتر).
  List<String> get categories {
    final set = <String>{'الكل'};
    for (final e in expenses) {
      if (e.category.trim().isNotEmpty) set.add(e.category);
    }
    return set.toList();
  }

  static const _sentinel = Object();

  ExpensesState copyWith({
    ExpensesStatus? status,
    List<ExpenseModel>? expenses,
    ExpenseModel? addedExpense,
    Object? errorMessage = _sentinel,
    double? totalAmount,
    String? searchQuery,
    String? categoryFilter,
  }) {
    return ExpensesState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      addedExpense: addedExpense ?? this.addedExpense,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      totalAmount: totalAmount ?? this.totalAmount,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }

  @override
  List<Object?> get props => [status, expenses, addedExpense, errorMessage, totalAmount, searchQuery, categoryFilter];
}

/// تنسيق رقم (صحيح من غير كسور).
String fmtExp(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
