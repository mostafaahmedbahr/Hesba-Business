import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';
import '../views/add_expense_view.dart';
import '../../data/models/expense_model.dart';

class ExpensesView extends StatefulWidget {
  final String? shopId;
  const ExpensesView({super.key, this.shopId});
  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _filterCategory = 'الكل';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd(BuildContext ctx, [ExpenseModel? expense]) async {
    HapticFeedback.lightImpact();
    final res = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => AddExpenseView(shopId: widget.shopId, expense: expense)));
    if (res == true && ctx.mounted) {
      try { ctx.read<ExpensesCubit>().loadExpenses(shopId: widget.shopId ?? ''); } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpensesCubit(expensesRepo: sl())..loadExpenses(shopId: widget.shopId ?? ''),
      child: BlocBuilder<ExpensesCubit, ExpensesState>(
        builder: (context, state) {
          final cubit = context.read<ExpensesCubit>();

          // حالة التحميل الأولى
          if (state.status == ExpensesStatus.loading && state.expenses.isEmpty) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: CustomScrollView(slivers: [
                _buildHeader(context, 0, 0, 0, 0, onAdd: () => _openAdd(context)),
                const SliverFillRemaining(hasScrollBody: false, child: _LoadingView()),
              ]),
            );
          }

          // حالة الخطأ
          if (state.status == ExpensesStatus.error && state.expenses.isEmpty) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: CustomScrollView(slivers: [
                _buildHeader(context, 0, 0, 0, 0, onAdd: () => _openAdd(context)),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(message: state.errorMessage ?? 'حدث خطأ', onRetry: () => cubit.loadExpenses(shopId: widget.shopId ?? '')),
                ),
              ]),
            );
          }

          // فارغة تماماً
          if (state.expenses.isEmpty) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              floatingActionButton: FloatingActionButton.extended(
                heroTag: 'expenses_fab_empty',
                onPressed: () => _openAdd(context),
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: Text('إضافة مصروف', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
              ),
              body: _EmptyStateScaffold(onAdd: () => _openAdd(context)),
            );
          }

          // يوجد بيانات — احسب الإحصائيات والفلترة
          final expenses = state.expenses;
          final total = state.totalAmount;
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayList = expenses.where((e) => _isSameDay(e.date, todayStart) || e.date.isAfter(todayStart)).toList();
          final todayTotal = todayList.fold<double>(0, (s, e) => s + e.amount);

          final q = _query.trim().toLowerCase();
          final filtered = expenses.where((e) {
            final matchesSearch = q.isEmpty || e.title.toLowerCase().contains(q) || e.category.toLowerCase().contains(q) || e.note.toLowerCase().contains(q);
            final matchesCat = _filterCategory == 'الكل' || e.category == _filterCategory;
            return matchesSearch && matchesCat;
          }).toList();

          final categories = <String>{'الكل'};
          for (final e in expenses) if (e.category.isNotEmpty) categories.add(e.category);

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
            ).animate().scale(delay: 400.ms),
            body: RefreshIndicator(
              onRefresh: () async => cubit.loadExpenses(shopId: widget.shopId ?? ''),
              child: CustomScrollView(
                slivers: [
                  _buildHeader(context, expenses.length, total, todayList.length, todayTotal, onAdd: () => _openAdd(context)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                      child: Column(children: [
                        Container(
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _query = v),
                            textInputAction: TextInputAction.search,
                            style: TextStyle(fontSize: 13.5.sp),
                            decoration: InputDecoration(
                              hintText: 'ابحث بالعنوان أو التصنيف أو الملاحظة',
                              hintStyle: TextStyle(fontSize: 12.5.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              prefixIcon: Container(margin: EdgeInsets.all(8.w), width: 36.w, height: 36.w, decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.search_rounded, size: 18.sp, color: const Color(0xFFE11D48))),
                              suffixIcon: _query.isEmpty ? null : IconButton(icon: Icon(Icons.close_rounded, size: 18.sp), onPressed: () { _searchController.clear(); setState(() => _query = ''); }),
                              border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          height: 36.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => SizedBox(width: 8.w),
                            itemBuilder: (context, i) {
                              final cat = categories.elementAt(i);
                              final selected = cat == _filterCategory;
                              return ChoiceChip(
                                label: Text(cat, style: TextStyle(fontSize: 11.5.sp, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
                                selected: selected,
                                onSelected: (_) => setState(() => _filterCategory = cat),
                                selectedColor: const Color(0xFFE11D48),
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                side: BorderSide(color: selected ? const Color(0xFFE11D48) : const Color(0xFFE5E7EB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                                showCheckmark: false,
                                padding: EdgeInsets.symmetric(horizontal: 14.w),
                              );
                            },
                          ),
                        ),
                      ]),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                      child: _AddExpenseCTA(onTap: () => _openAdd(context)),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(child: _buildNoResults(context, onClear: () { _searchController.clear(); setState(() { _query = ''; _filterCategory = 'الكل'; }); }))
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (itemCtx, index) {
                          final expense = filtered[index];
                          return Dismissible(
                            key: ValueKey(expense.expenseId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20.w),
                              margin: EdgeInsets.symmetric(vertical: 4.h),
                              decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(20.r)),
                              child: Icon(Icons.delete_rounded, color: Colors.white, size: 26.sp),
                            ),
                            confirmDismiss: (_) async {
                              final confirmed = await _showDeleteConfirm(itemCtx, expense, cubit);
                              if (confirmed == true) cubit.deleteExpense(expenseId: expense.expenseId, shopId: widget.shopId ?? '');
                              return confirmed ?? false;
                            },
                            child: _ExpenseCardPremium(expense: expense, onEdit: () => _openAdd(context, expense), onDelete: () async {
                              final ok = await _showDeleteConfirm(context, expense, cubit);
                              if (ok == true) cubit.deleteExpense(expenseId: expense.expenseId, shopId: widget.shopId ?? '');
                            }).animate(delay: (40 * index).ms).fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count, double total, int todayCount, double todayTotal, {VoidCallback? onAdd}) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 192.h,
      backgroundColor: const Color(0xFFE11D48),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      stretch: true,
      centerTitle: true,
      title: count > 0
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('المصروفات', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(width: 8.w),
              Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)), child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF9F1239)))),
            ])
          : const Text('المصروفات', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF881337), Color(0xFFE11D48), Color(0xFFFB7185)])),
          child: Stack(children: [
            Positioned(top: -40.h, left: -30.w, child: Container(width: 140.w, height: 140.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
            Positioned(bottom: -30.h, right: -20.w, child: Container(width: 180.w, height: 180.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 12.h),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Flexible(child: Text('المصروفات', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 20.w, height: 20.w, decoration: BoxDecoration(color: const Color(0xFFE11D48), shape: BoxShape.circle), child: Icon(Icons.numbers_rounded, size: 11.sp, color: Colors.white)),
                            SizedBox(width: 6.w),
                            Text('$count', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFF9F1239))),
                          ]),
                        ),
                      ]),
                      SizedBox(height: 4.h),
                      Text(count == 0 ? 'لا يوجد مصروفات' : '$count مصروف • إجمالي ${_fmt(total)} ج.م', style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    SizedBox(width: 10.w),
                    if (onAdd != null)
                      Material(color: Colors.white, borderRadius: BorderRadius.circular(13.r), child: InkWell(onTap: () { HapticFeedback.lightImpact(); onAdd(); }, borderRadius: BorderRadius.circular(13.r), child: Container(width: 42.w, height: 42.w, child: Icon(Icons.add_rounded, size: 22.sp, color: const Color(0xFFBE123C))))),
                  ])),
                  SizedBox(height: 10.h),
                  Row(children: [
                    Expanded(child: _headerGlass(icon: Icons.payments_rounded, label: 'إجمالي المصروفات', value: '${_fmt(total)} ج.م')),
                    SizedBox(width: 10.w),
                    Expanded(child: _headerGlass(icon: Icons.today_rounded, label: 'مصروفات اليوم', value: todayCount > 0 ? '$todayCount • ${_fmt(todayTotal)}' : '0', danger: todayCount > 0)),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _headerGlass({required IconData icon, required String label, required String value, bool danger = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
      child: Row(children: [
        Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: Colors.white)),
        SizedBox(width: 8.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white)),
        ])),
      ]),
    );
  }

  Widget _buildNoResults(BuildContext context, {VoidCallback? onClear}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 0),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
      child: Column(children: [
        Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFFE4E6), shape: BoxShape.circle), child: Icon(Icons.search_off_rounded, size: 28.sp, color: const Color(0xFFFB7185))),
        SizedBox(height: 12.h),
        Text('لا توجد نتائج', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        SizedBox(height: 6.h),
        Text('جرّب كلمة بحث أخرى أو غيّر الفلتر', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
        if (onClear != null) ...[
          SizedBox(height: 14.h),
          OutlinedButton(onPressed: onClear, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))), child: Text('مسح الفلتر')),
        ],
      ]),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context, ExpenseModel expense, ExpensesCubit cubit) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(22.r)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFEF2F2), shape: BoxShape.circle), child: Icon(Icons.delete_rounded, size: 26.sp, color: const Color(0xFFE11D48))),
            SizedBox(height: 14.h),
            Text('حذف المصروف؟', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            Text('هل أنت متأكد من حذف "${expense.title}"؟ لا يمكن التراجع.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF64748B))),
            SizedBox(height: 18.h),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h)), child: Text('إلغاء'))),
              SizedBox(width: 10.w),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h)), child: Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
            ]),
          ]),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ExpenseCardPremium extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ExpenseCardPremium({required this.expense, required this.onEdit, required this.onDelete});

  Color _catColor(String cat) {
    switch (cat) {
      case 'إيجار': return const Color(0xFF2563EB);
      case 'رواتب': return const Color(0xFF7C3AED);
      case 'مرافق': return const Color(0xFFF59E0B);
      case 'مستلزمات': return const Color(0xFF059669);
      default: return const Color(0xFFE11D48);
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'إيجار': return Icons.home_rounded;
      case 'رواتب': return Icons.payments_rounded;
      case 'مرافق': return Icons.bolt_rounded;
      case 'مستلزمات': return Icons.shopping_bag_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _catColor(expense.category);
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 44.w, height: 44.w, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)]), borderRadius: BorderRadius.circular(12.r)), child: Icon(_catIcon(expense.category), color: Colors.white, size: 20.sp)),
              SizedBox(width: 12.w),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                SizedBox(height: 3.h),
                Row(children: [
                  Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.18))), child: Text(expense.category.isEmpty ? 'عام' : expense.category, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: color))),
                  SizedBox(width: 6.w),
                  Icon(Icons.calendar_today_rounded, size: 11.sp, color: const Color(0xFF94A3B8)),
                  SizedBox(width: 3.w),
                  Text('${expense.date.day}/${expense.date.month}/${expense.date.year}', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.12))), child: Text('-${_fmt(expense.amount)} ج.م', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFFE11D48)))),
              ]),
            ]),
            if (expense.note.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Container(width: double.infinity, padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.notes_rounded, size: 13.sp, color: const Color(0xFF94A3B8)), SizedBox(width: 6.w), Expanded(child: Text(expense.note, style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))))])),
            ],
            SizedBox(height: 10.h),
            Row(children: [
              _actionBtn(Icons.edit_outlined, const Color(0xFF1A4FD6), 'تعديل', onEdit, isDark),
              SizedBox(width: 8.w),
              _actionBtn(Icons.delete_outline_rounded, const Color(0xFFE11D48), 'حذف', onDelete, isDark),
              const Spacer(),
              Icon(Icons.chevron_left_rounded, size: 18.sp, color: const Color(0xFFCBD5E1)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: color.withValues(alpha: 0.14))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13.sp, color: color), SizedBox(width: 5.w), Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: color))]),
      ),
    );
  }
}

class _AddExpenseCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _AddExpenseCTA({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: () { HapticFeedback.mediumImpact(); onTap(); },
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18.r), border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.22), width: 1.2), gradient: LinearGradient(colors: [const Color(0xFFFFF1F2), isDark ? AppTheme.darkSurface : Colors.white]), boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6))]),
          child: Row(children: [
            Container(width: 48.w, height: 48.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFFB7185)]), borderRadius: BorderRadius.circular(14.r), boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4))]), child: Icon(Icons.add_rounded, size: 24.sp, color: Colors.white)),
            SizedBox(width: 12.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('إضافة مصروف جديد', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              SizedBox(height: 3.h),
              Text('سجل مصروفك وسيُخصم من الرصيد تلقائياً', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
            ])),
            Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: const Color(0xFFFFE4E6), shape: BoxShape.circle), child: Icon(Icons.arrow_forward_rounded, size: 16.sp, color: const Color(0xFFE11D48))),
          ]),
        ),
      ),
    );
  }
}

class _EmptyStateScaffold extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyStateScaffold({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        expandedHeight: 192.h,
        backgroundColor: const Color(0xFFE11D48),
        flexibleSpace: FlexibleSpaceBar(background: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF881337), Color(0xFFE11D48), Color(0xFFFB7185)])), child: SafeArea(bottom: false, child: Padding(padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 12.h), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
          Row(children: [Expanded(child: Text('المصروفات', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.white))), Material(color: Colors.white, borderRadius: BorderRadius.circular(12.r), child: InkWell(onTap: onAdd, borderRadius: BorderRadius.circular(12.r), child: Container(width: 36.w, height: 36.w, child: Icon(Icons.add_rounded, color: const Color(0xFFBE123C)))))]),
          SizedBox(height: 10.h),
          Row(children: [Expanded(child: _HeaderGlassEmpty(icon: Icons.payments_rounded, label: 'إجمالي المصروفات', value: '0 ج.م')), SizedBox(width: 10.w), Expanded(child: _HeaderGlassEmpty(icon: Icons.today_rounded, label: 'مصروفات اليوم', value: '0'))]),
        ]))))),
      ),
      SliverFillRemaining(hasScrollBody: false, child: _EmptyState(onAdd: onAdd)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 28.w), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 96.w, height: 96.w, decoration: BoxDecoration(color: const Color(0xFFFFE4E6), shape: BoxShape.circle), child: Icon(Icons.savings_rounded, size: 44.sp, color: const Color(0xFFE11D48))),
      SizedBox(height: 16.h),
      Text('لا توجد مصروفات مسجلة', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      SizedBox(height: 8.h),
      Text('ابدأ بإضافة أول مصروف وتابع رصيدك بدقة', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B), height: 1.5)),
      SizedBox(height: 20.h),
      SizedBox(width: double.infinity, height: 50.h, child: FilledButton.icon(onPressed: onAdd, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))), icon: const Icon(Icons.add_rounded), label: Text('إضافة مصروف', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800)))),
    ])));
  }
}

Widget _HeaderGlassEmpty({required IconData icon, required String label, required String value}) {
  return Container(padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.white.withValues(alpha: 0.20))), child: Row(children: [Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: Colors.white)), SizedBox(width: 8.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w600)), Text(value, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white))]))]));
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 36.w, height: 36.w, child: CircularProgressIndicator(strokeWidth: 3, color: const Color(0xFFE11D48))), SizedBox(height: 12.h), Text('جاري تحميل المصروفات...', style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurfaceVariant))]));
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 28.w), child: Container(padding: EdgeInsets.all(22.w), decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFEF2F2), shape: BoxShape.circle), child: Icon(Icons.error_outline_rounded, size: 28.sp, color: const Color(0xFFE11D48))),
      SizedBox(height: 12.h),
      Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      SizedBox(height: 16.h),
      SizedBox(width: double.infinity, height: 46.h, child: FilledButton.icon(onPressed: onRetry, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))), icon: const Icon(Icons.refresh_rounded, size: 18), label: Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.w700)))),
    ]))));
  }
}

String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
