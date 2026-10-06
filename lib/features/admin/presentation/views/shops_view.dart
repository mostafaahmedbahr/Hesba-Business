import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ui.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<AdminListCubit, AdminListState>(
      builder: (context, state) {
        if (state.loading && state.docs.isEmpty) {
          return Column(
            children: [
              _buildSearchBar(context, enabled: false),
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
              _buildSearchBar(context, enabled: false),
              Expanded(child: adminEmpty(Icons.storefront_outlined, 'لا توجد محلات بعد')),
            ],
          );
        }

        final types = _extractTypes(state.docs);
        final filtered = _applyFilter(state.docs);

        return RefreshIndicator(
          onRefresh: () => context.read<AdminListCubit>().firstPage(),
          child: Column(
            children: [
              _buildSummaryHeader(context, total: state.docs.length, shown: filtered.length, loading: state.loading),
              _buildSearchBar(context, enabled: true),
              if (types.length > 1) _buildTypeChips(types),
              if (_query.isNotEmpty || _selectedType != 'الكل')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'نتائج البحث: ${filtered.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.darkTextSecondary : Colors.grey[600],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _query = '';
                          _searchCtrl.clear();
                          _selectedType = 'الكل';
                        }),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('مسح الفلتر', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? adminEmpty(Icons.search_off_outlined, 'لا توجد نتائج مطابقة لبحثك')
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 760;
                          if (wide) {
                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth >= 1100 ? 3 : 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 132,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => _ShopCard(doc: filtered[i]),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: _ShopCard(doc: filtered[i]),
                            ),
                          );
                        },
                      ),
              ),
              if (state.hasMore)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: state.loading ? null : () => context.read<AdminListCubit>().nextPage(),
                        icon: state.loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.expand_more, size: 20),
                        label: Text(state.loading ? 'جاري التحميل...' : 'تحميل المزيد (${state.docs.length} معروض)'),
                      ),
                    ),
                  ),
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
      if (_selectedType != 'الكل' && (data['businessType'] as String? ?? '') != _selectedType) {
        return false;
      }
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

  Widget _buildSummaryHeader(BuildContext context, {required int total, required int shown, required bool loading}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إجمالي المحلات', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$total', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Text('محل', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isDark)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  shown == total ? 'الكل معروض' : 'عرض $shown من $total',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(width: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: loading ? null : () => context.read<AdminListCubit>().firstPage(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.refresh, color: AppTheme.primaryColor, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, {required bool enabled}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        enabled: enabled,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم، المدينة، الهاتف...',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() {
                    _query = '';
                    _searchCtrl.clear();
                  }),
                ),
          filled: true,
          fillColor: isDark ? AppTheme.darkSurface : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChips(List<String> types) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: types.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = types[i];
          final selected = t == _selectedType;
          return ChoiceChip(
            label: Text(t, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
            selected: selected,
            onSelected: (_) => setState(() => _selectedType = t),
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(color: selected ? Colors.white : null),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = (data['shopName'] as String?)?.trim().ifEmpty ?? 'بدون اسم';
    final phone = (data['shopPhone'] as String?)?.trim() ?? (data['phone'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final address = (data['address'] as String?)?.trim() ?? '';
    final type = (data['businessType'] as String?)?.trim() ?? '';
    final imageUrl = (data['shopImageUrl'] as String?)?.trim() ?? '';
    final isActive = (data['isActive'] as bool?) ?? true;
    final createdAt = _formatDate(data['createdAt']);
    final shortId = doc.id.length > 8 ? doc.id.substring(0, 8) : doc.id;

    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.black.withValues(alpha: 0.06);
    final subColor = isDark ? AppTheme.darkTextSecondary : Colors.grey[600];

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShopDetailsView(
              shopId: doc.id,
              ownerId: data['ownerId'] as String? ?? '',
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: isDark ? null : AppTheme.cardShadow(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageUrl.isEmpty
                        ? Container(
                            width: 62,
                            height: 62,
                            color: AppTheme.primarySoft,
                            child: const Icon(Icons.storefront_outlined, color: AppTheme.primaryColor, size: 30),
                          )
                        : Image.network(
                            imageUrl,
                            width: 62,
                            height: 62,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 62,
                              height: 62,
                              color: AppTheme.primarySoft,
                              child: const Icon(Icons.storefront_outlined, color: AppTheme.primaryColor, size: 30),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.successColor : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 14.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '#$shortId',
                          style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.darkTextSecondary : Colors.grey[400], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (phone.isNotEmpty)
                      _metaRow(Icons.phone_outlined, phone, subColor),
                    if (city.isNotEmpty || address.isNotEmpty)
                      _metaRow(
                        Icons.location_on_outlined,
                        [city, address].where((e) => e.isNotEmpty).join(' • '),
                        subColor,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (type.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
                            ),
                          ),
                        if (type.isNotEmpty) const SizedBox(width: 6),
                        if (createdAt.isNotEmpty)
                          Text(
                            createdAt,
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_left_rounded, color: isDark ? AppTheme.darkTextSecondary : Colors.black26, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic v) {
    try {
      if (v == null) return '';
      if (v is Timestamp) {
        final d = v.toDate();
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }
      return '';
    } catch (_) {
      return '';
    }
  }
}

extension _StrX on String {
  String? get ifEmpty => trim().isEmpty ? null : trim();
}
