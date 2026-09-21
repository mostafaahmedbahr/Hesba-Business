import 'package:equatable/equatable.dart';

import '../../data/models/expense_model.dart';

enum ExpensesStatus { initial, loading, success, error }

class ExpensesState extends Equatable {
  final ExpensesStatus status;
  final List<ExpenseModel> expenses;
  final ExpenseModel? addedExpense;
  final String? errorMessage;
  final double totalAmount;

  const ExpensesState({
    this.status = ExpensesStatus.initial,
    this.expenses = const [],
    this.addedExpense,
    this.errorMessage,
    this.totalAmount = 0,
  });

  static const _sentinel = Object();

  ExpensesState copyWith({
    ExpensesStatus? status,
    List<ExpenseModel>? expenses,
    ExpenseModel? addedExpense,
    Object? errorMessage = _sentinel,
    double? totalAmount,
  }) {
    return ExpensesState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      addedExpense: addedExpense ?? this.addedExpense,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  @override
  List<Object?> get props => [status, expenses, addedExpense, errorMessage, totalAmount];
}
