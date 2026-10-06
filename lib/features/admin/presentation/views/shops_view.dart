import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/admin/presentation/views/shop_details_view.dart';

class ShopsView extends StatelessWidget {
  const ShopsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getShopsPage(startAfter: startAfter),
      )..firstPage(),
      child: const _ShopsBody(),
    );
  }
}

class _ShopsBody extends StatefulWidget {
  const _ShopsBody();

  @override
  State<_ShopsBody> createState() => _ShopsBodyState();
}

class _ShopsBodyState extends State<_ShopsBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedType = 'الكل';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminListCubit, AdminListState>(
      builder: (context, state) {
        if (state.loading && state.docs.isEmpty) {
          return Column(
            children: [
              AdminSearchField(controller: _searchCtrl, hint: 'ابحث بالاسم، المدينة، الهاتف...', enabled: false),
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
              AdminSearchField(controller: _searchCtrl, hint: 'ابحث بالاسم، المدينة، الهاتف...', enabled: false),
              Expanded(
                  child: adminEmpty(Icons.storefront_outlined, 'لا توجد محلات بعد', 'عند تسجيل أول محل سيظهر هنا')),
            ],
          );
        }

        final types = _extractTypes(state.docs);
        final filtered = _applyFilter(state.docs);
        final filtering = _query.isNotEmpty || _selectedType != 'الكل';

        return RefreshIndicator(
          onRefresh: () => context.read<AdminListCubit>().firstPage(),
          child: Column(
            children: [
              const AdminPageHeader(title: 'المحلات', description: 'إدارة ومراجعة جميع المحلات المسجلة في النظام'),
              AdminSummaryHeader(
                icon: Icons.storefront_outlined,
                title: 'إجمالي المحلات',
                total: state.docs.length,
                unit: 'محل',
                stats: [if (!filtering) 'الكل معروض' else 'عرض ${filtered.length} من ${state.docs.length}'],
                loading: state.loading,
                onRefresh: () => context.read<AdminListCubit>().firstPage(),
              ),
              AdminSearchField(
                controller: _searchCtrl,
                hint: 'ابحث بالاسم، المدينة، الهاتف...',
                onChanged: (v) => setState(() => _query = v),
              ),
              AdminFilterChips(
                selected: _selectedType,
                onSelect: (k) => setState(() => _selectedType = k),
                items: [for (final t in types) AdminChipItem(t, t)],
              ),
              if (filtering)
                AdminResultCount(
                  count: filtered.length,
                  onClear: () => setState(() {
                    _query = '';
                    _searchCtrl.clear();
                    _selectedType = 'الكل';
                  }),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? adminEmpty(Icons.search_off_outlined, 'لا توجد نتائج مطابقة لبحثك', 'جرّب كلمة مختلفة أو امسح الفلتر')
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 760;
                          if (wide) {
                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(AdminSpace.lg, AdminSpace.xs, AdminSpace.lg, AdminSpace.lg),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth >= 1100 ? 3 : 2,
                                crossAxisSpacing: AdminSpace.md,
                                mainAxisSpacing: AdminSpace.md,
                                mainAxisExtent: 138,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => _ShopCard(doc: filtered[i]),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(0, AdminSpace.xs, 0, AdminSpace.lg),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AdminSpace.sm),
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AdminSpace.md),
                              child: _ShopCard(doc: filtered[i]),
                            ),
                          );
                        },
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
    );
  }

  List<String> _extractTypes(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final set = <String>{};
    for (final d in docs) {
      final t = (d.data()['businessType'] as String?)?.trim() ?? '';
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList()..sort();
    return ['الكل', ...list];
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final q = _query.trim();
    return docs.where((d) {
      final data = d.data();
      if (_selectedType != 'الكل' && (data['businessType'] as String? ?? '') != _selectedType) return false;
      if (q.isEmpty) return true;
      final haystack = [
        data['shopName'],
        data['city'],
        data['address'],
        data['shopPhone'],
        data['phone'],
        data['ownerId'],
        d.id,
      ].whereType<String>().join(' ');
      return haystack.contains(q);
    }).toList();
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final theme = Theme.of(context);

    final name = (data['shopName'] as String?)?.trim();
    final phone = (data['shopPhone'] as String?)?.trim() ?? (data['phone'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final address = (data['address'] as String?)?.trim() ?? '';
    final type = (data['businessType'] as String?)?.trim() ?? '';
    final imageUrl = (data['shopImageUrl'] as String?)?.trim() ?? '';
    final isActive = (data['isActive'] as bool?) ?? true;
    final sub = AdminColors.textSecondary(context);

    return AdminCard(
      padding: const EdgeInsets.all(AdminSpace.md),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShopDetailsView(shopId: doc.id, ownerId: data['ownerId'] as String? ?? ''),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              AdminThumbnail(url: imageUrl, size: 62, icon: Icons.storefront_outlined),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isActive ? AdminColors.success : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: AdminColors.surface(context), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AdminSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        (name == null || name.isEmpty) ? 'بدون اسم' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CopyableId(id: doc.id),
                  ],
                ),
                const SizedBox(height: AdminSpace.xs),
                if (phone.isNotEmpty) _meta(Icons.phone_outlined, phone, sub),
                if (city.isNotEmpty || address.isNotEmpty)
                  _meta(Icons.location_on_outlined, [city, address].where((e) => e.isNotEmpty).join(' • '), sub),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (type.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AdminRadius.pill),
                        ),
                        child: Text(type,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
                      ),
                    if (type.isNotEmpty) const SizedBox(width: 6),
                    Text(AdminFmt.dateNum(data['createdAt']), style: TextStyle(fontSize: 11, color: sub)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AdminSpace.xs),
          Icon(Icons.chevron_left_rounded, color: AdminColors.textMuted(context), size: 24),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}
