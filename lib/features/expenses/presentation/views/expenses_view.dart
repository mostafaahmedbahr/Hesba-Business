import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../data/models/expense_model.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';
import '../widgets/expense_delete_dialog.dart';
import '../widgets/expense_list_card.dart';
import '../widgets/expense_list_header.dart';
import '../widgets/expense_list_placeholders.dart';
import '../widgets/expense_list_search.dart';
import 'add_expense_view.dart';

/// شاشة المصروفات (عرض بس — اللوجيك في Cubit).
class ExpensesView extends StatelessWidget {
  final String? shopId;
  const ExpensesView({super.key, this.shopId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpensesCubit(expensesRepo: sl())..loadExpenses(shopId: shopId ?? ''),
      child: _ExpensesBody(shopId: shopId),
    );
  }
}

/// هيكل الشاشة (FAB + حالات + محتوى).
class _ExpensesBody extends StatelessWidget {
  final String? shopId;
  const _ExpensesBody({required this.shopId});

  /// يفتح إضافة/تعديل مصروف.
  Future<void> _openAdd(BuildContext context, [ExpenseModel? expense]) async {
    HapticFeedback.lightImpact();
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseView(shopId: shopId, expense: expense)),
    );
    if (res == true && context.mounted) {
      try {
        context.read<ExpensesCubit>().loadExpenses(shopId: shopId ?? '');
      } catch (_) {}
    }
  }

  /// تأكيد ثم حذف.
  Future<void> _confirmDelete(BuildContext context, ExpenseModel expense) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ExpenseDeleteDialog(title: expense.title),
    );
    if (ok == true && context.mounted) {
      context.read<ExpensesCubit>().deleteExpense(expenseId: expense.expenseId, shopId: shopId ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpensesCubit, ExpensesState>(
      builder: (context, state) {
        // بيحمل.
        if (state.status == ExpensesStatus.loading && state.expenses.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(slivers: [
              ExpenseListHeader(count: 0, totalValue: 0, todayCount: 0, todayValue: 0, onAdd: () => _openAdd(context)),
              const SliverFillRemaining(hasScrollBody: false, child: ExpenseListLoading()),
            ]),
          );
        }
        // خطأ.
        if (state.status == ExpensesStatus.error && state.expenses.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(slivers: [
              ExpenseListHeader(count: 0, totalValue: 0, todayCount: 0, todayValue: 0, onAdd: () => _openAdd(context)),
              SliverFillRemaining(
                hasScrollBody: false,
                child: ExpenseListError(
                  message: state.errorMessage ?? 'حدث خطأ',
                  onRetry: () => context.read<ExpensesCubit>().loadExpenses(shopId: shopId ?? ''),
                ),
              ),
            ]),
          );
        }
        final cubit = context.read<ExpensesCubit>();
        // فاضي خالص: زرار واحد بس.
        if (state.expenses.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(slivers: [
              const ExpenseListHeader(count: 0, totalValue: 0, todayCount: 0, todayValue: 0),
              SliverFillRemaining(
                hasScrollBody: false,
                child: ExpenseListEmpty(onAdd: () => _openAdd(context)),
              ),
            ]),
          );
        }
        // فيه داتا.
        final filtered = state.filtered;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'expenses_fab',
            onPressed: () => _openAdd(context),
            elevation: 0,
            backgroundColor: const Color(0xFFE11D48),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text('إضافة مصروف', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
          ),
          body: RefreshIndicator(
            color: const Color(0xFFE11D48),
            onRefresh: () async => cubit.loadExpenses(shopId: shopId ?? ''),
            child: CustomScrollView(
              slivers: [
                ExpenseListHeader(
                  count: state.expenses.length,
                  totalValue: state.totalAmount,
                  todayCount: state.todayList.length,
                  todayValue: state.todayTotal,
                  onAdd: () => _openAdd(context),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                    child: ExpenseListSearch(
                      query: state.searchQuery,
                      categoryFilter: state.categoryFilter,
                      categories: state.categories,
                      onSearchChanged: cubit.setSearch,
                      onFilterChanged: cubit.setCategoryFilter,
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: ExpenseListNoResults(
                      onClear: () {
                        cubit.setSearch('');
                        cubit.setCategoryFilter('الكل');
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (itemCtx, i) {
                        final expense = filtered[i];
                        return Dismissible(
                          key: ValueKey(expense.expenseId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20.w),
                            decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(22.r)),
                            child: Icon(Icons.delete_rounded, color: Colors.white, size: 26.sp),
                          ),
                          confirmDismiss: (_) => _confirmDelete(itemCtx, expense).then((_) => false),
                          child: ExpenseListCard(
                            expense: expense,
                            onEdit: () => _openAdd(context, expense),
                            onDelete: () => _confirmDelete(context, expense),
                          )
                              .animate(delay: (50 * i).ms)
                              .fadeIn(duration: 320.ms)
                              .slideY(begin: 0.06, end: 0),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
