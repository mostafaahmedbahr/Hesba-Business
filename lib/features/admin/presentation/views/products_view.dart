import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/admin/presentation/views/product_details_view.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
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
        fetch: (startAfter) => sl<AdminRepo>().getProductsPage(startAfter: startAfter),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) {
            return Column(
              children: [
                AdminSearchField(controller: _searchCtrl, hint: 'ابحث بالاسم، التصنيف، المحل...', enabled: false),
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
                AdminSearchField(controller: _searchCtrl, hint: 'ابحث بالاسم، التصنيف، المحل...', enabled: false),
                Expanded(child: adminEmpty(Icons.inventory_2_outlined, 'لا توجد منتجات بعد', 'عند إضافة أول منتج سيظهر هنا')),
              ],
            );
          }

          final cats = _extractCats(state.docs);
          final filtered = _applyFilter(state.docs);
          final filtering = _query.isNotEmpty || _category != 'الكل';

          return RefreshIndicator(
            onRefresh: () => context.read<AdminListCubit>().firstPage(),
            child: Column(
              children: [
                const AdminPageHeader(title: 'المنتجات', description: 'منتجات جميع المحلات المسجلة في النظام'),
                AdminSummaryHeader(
                  icon: Icons.inventory_2_outlined,
                  title: 'إجمالي المنتجات',
                  total: state.docs.length,
                  unit: 'منتج',
                  stats: [if (!filtering) 'الكل معروض' else 'عرض ${filtered.length} من ${state.docs.length}'],
                  loading: state.loading,
                  onRefresh: () => context.read<AdminListCubit>().firstPage(),
                ),
                AdminSearchField(
                  controller: _searchCtrl,
                  hint: 'ابحث بالاسم، التصنيف، المحل...',
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
                      : LayoutBuilder(builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 760;
                          if (wide) {
                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(AdminSpace.lg, AdminSpace.xs, AdminSpace.lg, AdminSpace.lg),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth >= 1100 ? 3 : 2,
                                crossAxisSpacing: AdminSpace.md,
                                mainAxisSpacing: AdminSpace.md,
                                mainAxisExtent: 132,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => _ProductCard(doc: filtered[i]),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(0, AdminSpace.xs, 0, AdminSpace.lg),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AdminSpace.sm),
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AdminSpace.md),
                              child: _ProductCard(doc: filtered[i]),
                            ),
                          );
                        }),
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
      final haystack = [data['name'], data['category'], data['shopId'], d.id].whereType<String>().join(' ');
      return haystack.contains(q);
    }).toList();
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    return AdminCard(
      padding: const EdgeInsets.all(AdminSpace.md),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailsView(data: d, id: doc.id)),
      ),
      child: Row(
        children: [
          AdminThumbnail(url: (d['imageUrl'] as String?) ?? '', size: 58, icon: Icons.inventory_2_outlined),
          const SizedBox(width: AdminSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text((d['name'] as String?) ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${d['category'] ?? '-'} • الكمية: ${d['stock'] ?? 0}',
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
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.tag)),
            child: Text(AdminFmt.money((d['price'] as num?) ?? 0),
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
