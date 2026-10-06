import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _method = 'الكل';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getSalesPage(startAfter: startAfter),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) {
            return Column(
              children: [
                AdminSearchField(controller: _searchCtrl, hint: 'ابحث برقم العملية أو المحل...', enabled: false),
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
                AdminSearchField(controller: _searchCtrl, hint: 'ابحث برقم العملية أو المحل...', enabled: false),
                Expanded(child: adminEmpty(Icons.point_of_sale_outlined, 'لا توجد مبيعات بعد', 'عند تسجيل أول عملية بيع ستظهر هنا')),
              ],
            );
          }

          final methods = _extractMethods(state.docs);
          final filtered = _applyFilter(state.docs);
          final filtering = _query.isNotEmpty || _method != 'الكل';
          final revenue = filtered.fold<num>(0, (acc, d) => acc + ((d.data()['total'] as num?) ?? 0));

          return RefreshIndicator(
            onRefresh: () => context.read<AdminListCubit>().firstPage(),
            child: Column(
              children: [
                const AdminPageHeader(title: 'المبيعات', description: 'عمليات البيع في جميع المحلات المسجلة'),
                AdminSummaryHeader(
                  icon: Icons.point_of_sale_outlined,
                  title: 'إجمالي الإيرادات (المعروض)',
                  total: revenue.toInt(),
                  unit: 'ج',
                  stats: ['العمليات: ${filtered.length}'],
                  loading: state.loading,
                  onRefresh: () => context.read<AdminListCubit>().firstPage(),
                ),
                AdminSearchField(
                  controller: _searchCtrl,
                  hint: 'ابحث برقم العملية أو المحل...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                AdminFilterChips(
                  selected: _method,
                  onSelect: (k) => setState(() => _method = k),
                  items: [for (final m in methods) AdminChipItem(m, m)],
                ),
                if (filtering)
                  AdminResultCount(
                    count: filtered.length,
                    onClear: () => setState(() {
                      _query = '';
                      _searchCtrl.clear();
                      _method = 'الكل';
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
                            child: _SaleCard(doc: filtered[i]),
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

  List<String> _extractMethods(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final set = <String>{};
    for (final d in docs) {
      final m = (d.data()['paymentMethod'] as String?)?.trim() ?? '';
      if (m.isNotEmpty) set.add(m);
    }
    return ['الكل', ...set.toList()..sort()];
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilter(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final q = _query.trim();
    return docs.where((d) {
      final data = d.data();
      if (_method != 'الكل' && (data['paymentMethod'] as String? ?? '') != _method) return false;
      if (q.isEmpty) return true;
      final haystack = [data['shopId'], data['paymentMethod'], d.id].whereType<String>().join(' ');
      return haystack.contains(q);
    }).toList();
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final method = (d['paymentMethod'] as String?)?.trim() ?? '';
    return AdminCard(
      padding: const EdgeInsets.all(AdminSpace.md),
      onTap: () => showAdminSheet(context, _SaleSheet(data: d, id: doc.id)),
      child: Row(
        children: [
          const AdminIconTile(icon: Icons.point_of_sale_outlined, color: AdminColors.success, size: 44),
          const SizedBox(width: AdminSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AdminFmt.money((d['total'] as num?) ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(
                  '${AdminFmt.dateNum(d['createdAt'])}${method.isNotEmpty ? ' • $method' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12),
                ),
                const SizedBox(height: 2),
                CopyableId(id: doc.id),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: AdminColors.textMuted(context), size: 22),
        ],
      ),
    );
  }
}

class _SaleSheet extends StatelessWidget {
  const _SaleSheet({required this.data, required this.id});
  final Map<String, dynamic> data;
  final String id;

  @override
  Widget build(BuildContext context) {
    final shopId = (data['shopId'] as String?) ?? '';
    return AdminSheetShell(
      title: 'تفاصيل عملية البيع',
      subtitle: AdminFmt.money((data['total'] as num?) ?? 0),
      child: Column(
        children: [
          CopyableId(id: id, full: true, label: 'معرف العملية'),
          const Divider(height: 20),
          if (shopId.isNotEmpty) ...[
            CopyableId(id: shopId, full: true, label: 'معرف المحل'),
            const Divider(height: 20),
          ],
          AdminInfoRow(icon: Icons.payments_outlined, label: 'الإجمالي', value: AdminFmt.money((data['total'] as num?) ?? 0)),
          const Divider(height: 14),
          AdminInfoRow(icon: Icons.calendar_month_outlined, label: 'التاريخ', value: AdminFmt.dateTime(data['createdAt'])),
          if ((data['paymentMethod'] as String?)?.isNotEmpty ?? false) ...[
            const Divider(height: 14),
            AdminInfoRow(icon: Icons.wallet_outlined, label: 'طريقة الدفع', value: data['paymentMethod'].toString()),
          ],
          if (data['items'] is List) ...[
            const Divider(height: 14),
            AdminInfoRow(icon: Icons.list_alt_outlined, label: 'عدد الأصناف', value: '${(data['items'] as List).length}'),
          ],
        ],
      ),
    );
  }
}
