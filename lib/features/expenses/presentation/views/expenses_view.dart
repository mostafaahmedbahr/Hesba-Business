import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_summary.dart';
import '../views/add_expense_view.dart';
import '../../data/models/expense_model.dart';

class ExpensesView extends StatelessWidget {
  final String? shopId;

  const ExpensesView({super.key, this.shopId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpensesCubit(expensesRepo: sl())..loadExpenses(shopId: shopId ?? ''),
      child: BlocListener<ExpensesCubit, ExpensesState>(
        listener: (ctx, state) {},
        child: Scaffold(
          appBar: AppBar(
            title: const Text('المصروفات'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => context.read<ExpensesCubit>().loadExpenses(shopId: shopId ?? ''),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'expenses_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddExpenseView(shopId: shopId)),
            ),
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text('إضافة مصروف', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
          ),
          body: BlocBuilder<ExpensesCubit, ExpensesState>(
            builder: (ctx, state) {
              final cubit = ctx.read<ExpensesCubit>();
              if (state.status == ExpensesStatus.loading && state.expenses.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.expenses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64.sp, color: Colors.grey.shade400),
                      SizedBox(height: 16.h),
                      Text('لا توجد مصروفات مسجلة', style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => cubit.loadExpenses(shopId: shopId ?? ''),
                child: ListView.builder(
                  padding: EdgeInsets.all(12.w),
                  itemCount: state.expenses.length,
                  itemBuilder: (itemCtx, index) {
                    final expense = state.expenses[index];
                    return Dismissible(
                      key: ValueKey(expense.expenseId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.w),
                        margin: EdgeInsets.symmetric(vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Icon(Icons.delete_rounded, color: Colors.white, size: 28.sp),
                      ),
                      confirmDismiss: (_) async {
                        final confirmed = await _showDeleteConfirm(itemCtx, expense, cubit);
                        if (confirmed ?? false) {
                          cubit.deleteExpense(expenseId: expense.expenseId, shopId: shopId ?? '');
                        }
                        return confirmed ?? false;
                      },
                      child: ExpenseCard(
                        title: expense.title,
                        category: expense.category,
                        amount: expense.amount,
                        note: expense.note,
                        date: expense.date,
                        onEdit: () => Navigator.push(
                          itemCtx,
                          MaterialPageRoute(
                            builder: (_) => AddExpenseView(shopId: shopId, expense: expense),
                          ),
                        ),
                        onDelete: () => cubit.deleteExpense(expenseId: expense.expenseId, shopId: shopId ?? ''),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context, ExpenseModel expense, ExpensesCubit cubit) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.delete_rounded, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('حذف المصروف', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text('هل أنت متأكد من حذف "${expense.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
