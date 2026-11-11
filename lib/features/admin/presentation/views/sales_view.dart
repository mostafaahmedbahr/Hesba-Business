import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/sales/presentation/cubit/sales_list_state.dart';

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
                  // القيمة خام للفلترة (cash/...) واللي يظهر عربي زي شاشة العميل.
                  items: [
                    for (final m in methods)
                      AdminChipItem(m, m == 'الكل' ? m : SalesListState.paymentLabel(m)),
                  ],
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
      // البحث يشمل القيمة الخام (cash) والاسم العربي (نقدي).
      final rawMethod = (data['paymentMethod'] as String?) ?? '';
      final haystack = [
        data['shopId'],
        rawMethod,
        SalesListState.paymentLabel(rawMethod),
        data['personName'],
        data['personPhone'],
        d.id,
      ].whereType<String>().join(' ');
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

    final shopName = (d['shopName'] as String?) ?? '-';
    final total = (d['total'] as num?) ?? 0;
    final method = (d['paymentMethod'] as String?)?.trim() ?? '';
    final date = AdminFmt.dateNum(d['createdAt']);
    final itemsCount = d['items'] is List
        ? (d['items'] as List).length
        : 0;
    final customerName = (d['personName'] as String?)?.trim() ?? '';
    final customerPhone = (d['personPhone'] as String?)?.trim() ?? '';

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
                  color: AdminColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AdminColors.success,
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
                  color: AdminColors.success.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'عملية بيع',
                  style: TextStyle(
                    color: AdminColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sale Details
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminColors.success.withValues(alpha: 0.045),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AdminColors.success.withValues(alpha: 0.09),
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
                            Icons.shopping_bag_outlined,
                            size: 15,
                            color: secondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'تفاصيل البيع',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '$itemsCount أصناف',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      if (method.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.wallet_outlined,
                              size: 14,
                              color: secondary,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                SalesListState.paymentLabel(method),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (customerName.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: secondary,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                customerPhone.isNotEmpty
                                    ? '$customerName • $customerPhone'
                                    : customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Container(
                  width: 1,
                  height: 75,
                  color: AdminColors.success.withValues(alpha: 0.15),
                ),

                const SizedBox(width: 12),

                Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AdminColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.point_of_sale_rounded,
                        color: AdminColors.success,
                        size: 22,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      AdminFmt.money(total),
                      style: const TextStyle(
                        color: AdminColors.success,
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

