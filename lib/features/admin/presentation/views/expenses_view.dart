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
      final haystack = [data['title'], data['category'], data['shopId'], d.id].whereType<String>().join(' ');
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
    return AdminCard(
      padding: const EdgeInsets.all(AdminSpace.md),
      onTap: () => showAdminSheet(context, _ExpenseSheet(data: d, id: doc.id)),
      child: Row(
        children: [
          const AdminIconTile(icon: Icons.money_off_outlined, color: AdminColors.error, size: 44),
          const SizedBox(width: AdminSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((d['title'] as String?) ?? '-',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${d['category'] ?? '-'} • ${AdminFmt.dateNum(d['createdAt'] ?? d['date'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12)),
                const SizedBox(height: 2),
                CopyableId(id: doc.id),
              ],
            ),
          ),
          const SizedBox(width: AdminSpace.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration:
                BoxDecoration(color: AdminColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AdminRadius.tag)),
            child: Text(AdminFmt.money((d['amount'] as num?) ?? 0),
                style: const TextStyle(color: AdminColors.error, fontWeight: FontWeight.w800, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _ExpenseSheet extends StatelessWidget {
  const _ExpenseSheet({required this.data, required this.id});
  final Map<String, dynamic> data;
  final String id;

  @override
  Widget build(BuildContext context) {
    final shopId = (data['shopId'] as String?) ?? '';
    return AdminSheetShell(
      title: 'تفاصيل المصروف',
      subtitle: (data['title'] as String?) ?? '-',
      child: Column(
        children: [
          CopyableId(id: id, full: true, label: 'معرف المصروف'),
          const Divider(height: 20),
          if (shopId.isNotEmpty) ...[
            CopyableId(id: shopId, full: true, label: 'معرف المحل'),
            const Divider(height: 20),
          ],
          AdminInfoRow(icon: Icons.title_outlined, label: 'العنوان', value: (data['title'] as String?) ?? '-'),
          const Divider(height: 14),
          AdminInfoRow(icon: Icons.category_outlined, label: 'التصنيف', value: (data['category'] as String?) ?? '-'),
          const Divider(height: 14),
          AdminInfoRow(
              icon: Icons.payments_outlined, label: 'المبلغ', value: AdminFmt.money((data['amount'] as num?) ?? 0)),
          const Divider(height: 14),
          AdminInfoRow(
              icon: Icons.calendar_month_outlined, label: 'التاريخ', value: AdminFmt.dateTime(data['createdAt'] ?? data['date'])),
        ],
      ),
    );
  }
}
