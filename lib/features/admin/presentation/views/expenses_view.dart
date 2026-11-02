import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'الكل';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getExpensesPage(startAfter: startAfter),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) {
            return Column(
              children: [
                AdminSearchField(controller: _searchCtrl, hint: 'ابحث بالعنوان أو التصنيف أو المحل...', enabled: false),
                Expanded(child: adminSkeletonList(context)),
              ],
            );
          }
          if (state.error != null && state.docs.isEmpty) {
            return adminError(state.error!, () => context.read<AdminListCubit>().firstPage());
          }
          if (state.docs.isEmpty) {
            return Column(
              children: [
                AdminSearchField(controller: _searchCtrl, hint: 'ابحث بالعنوان أو التصنيف أو المحل...', enabled: false),
                Expanded(child: adminEmpty(Icons.money_off_outlined, 'لا توجد مصروفات بعد', 'عند تسجيل أول مصروف سيظهر هنا')),
              ],
            );
          }

          final cats = _extractCats(state.docs);
          final filtered = _applyFilter(state.docs);
          final filtering = _query.isNotEmpty || _category != 'الكل';
          final total = filtered.fold<num>(0, (acc, d) => acc + ((d.data()['amount'] as num?) ?? 0));

          return RefreshIndicator(
            onRefresh: () => context.read<AdminListCubit>().firstPage(),
            child: Column(
              children: [
                const AdminPageHeader(title: 'المصروفات', description: 'مصروفات جميع المحلات المسجلة في النظام'),
                AdminSummaryHeader(
                  icon: Icons.money_off_outlined,
                  title: 'إجمالي المصروفات (المعروض)',
                  total: total.toInt(),
                  unit: 'ج',
                  stats: ['العدد: ${filtered.length}'],
                  loading: state.loading,
                  onRefresh: () => context.read<AdminListCubit>().firstPage(),
                ),
                AdminSearchField(
                  controller: _searchCtrl,
                  hint: 'ابحث بالعنوان أو التصنيف أو المحل...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                AdminFilterChips(
                  selected: _category,
                  onSelect: (k) => setState(() => _category = k),
                  items: [for (final c in cats) AdminChipItem(c, c)],
                ),
                if (filtering)
                  AdminResultCount(
                    count: filtered.length,
                    onClear: () => setState(() {
                      _query = '';
                      _searchCtrl.clear();
                      _category = 'الكل';
                    }),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? adminEmpty(Icons.search_off_outlined, 'لا توجد نتائج مطابقة لبحثك', 'جرّب كلمة مختلفة أو امسح الفلتر')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(0, AdminSpace.xs, 0, AdminSpace.lg),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AdminSpace.sm),
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AdminSpace.md),
                            child: _ExpenseCard(doc: filtered[i]),
                          ),
                        ),
                ),
                if (state.hasMore)
                  AdminLoadMore(
                    loading: state.loading,
                    label: 'تحميل المزيد (${state.docs.length} معروض)',
                    onLoad: () => context.read<AdminListCubit>().nextPage(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _extractCats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final set = <String>{};
    for (final d in docs) {
      final c = (d.data()['category'] as String?)?.trim() ?? '';
      if (c.isNotEmpty) set.add(c);
    }
    return ['الكل', ...set.toList()..sort()];
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilter(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final q = _query.trim();
    return docs.where((d) {
      final data = d.data();
      if (_category != 'الكل' && (data['category'] as String? ?? '') != _category) return false;
      if (q.isEmpty) return true;
      final haystack = [data['title'], data['category'], data['shopName'], data['shopId'], d.id].whereType<String>().join(' ');
      return haystack.contains(q);
    }).toList();
  }
}



class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();

    final title = (d['title'] as String?) ?? '-';
    final shopName = (d['shopName'] as String?) ?? '-';
    final category = (d['category'] as String?) ?? '-';
    final amount = (d['amount'] as num?) ?? 0;
    final date = AdminFmt.dateNum(d['createdAt'] ?? d['date']);

    final secondary = AdminColors.textSecondary(context);

    return AdminCard(
      padding: const EdgeInsets.all(AdminSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Header
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AdminColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AdminColors.error,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اسم المحل',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AdminColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'مصروف',
                  style: TextStyle(
                    color: AdminColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Expense Content
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminColors.error.withValues(alpha: 0.045),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AdminColors.error.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 15,
                            color: secondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'التصنيف',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Container(
                  width: 1,
                  height: 70,
                  color: AdminColors.error.withValues(alpha: 0.15),
                ),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AdminColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: AdminColors.error,
                        size: 22,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      AdminFmt.money(amount),
                      style: const TextStyle(
                        color: AdminColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Footer
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 15,
                color: secondary,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              CopyableId(id: doc.id),
            ],
          ),
        ],
      ),
    );
  }
}


