import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repos/products_repo.dart';
import '../cubit/products_cubit.dart';
import '../states/products_state.dart';
import 'product_form_view.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});
  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoryFilter = 'الكل';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductsCubit(repo: sl<ProductsRepo>())..init(),
      child: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'products_fab',
              onPressed: () => _openForm(context),
              elevation: 0,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text('productsAdd'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
            ).animate().scale(delay: 400.ms, duration: 300.ms),
            body: switch (state.status) {
              ProductsStatus.failure => _buildFailure(context),
              ProductsStatus.loading => const _LoadingView(),
              ProductsStatus.success => _buildContent(context, state),
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductsState state) {
    final products = state.products;
    if (products.isEmpty) return _buildEmptyState(context);

    final q = _query.trim().toLowerCase();
    final filtered = products.where((p) {
      final matchesSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      final matchesCat = _categoryFilter == 'الكل' || p.category == _categoryFilter;
      return matchesSearch && matchesCat;
    }).toList();

    double inventoryValue = 0;
    for (final p in filtered) inventoryValue += p.costPrice * p.stock;
    final lowStockCount = filtered.where((p) => p.isLowStock).length;

    // unique categories for chips
    final categories = <String>{'الكل'};
    for (final p in products) if (p.category.isNotEmpty) categories.add(p.category);

    return CustomScrollView(
      slivers: [
        _buildHeader(context, products.length, inventoryValue, lowStockCount),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Column(
              children: [
                // بحث بريميوم
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                    boxShadow: AppTheme.cardShadow(context),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    style: TextStyle(fontSize: 13.5.sp),
                    decoration: InputDecoration(
                      hintText: 'productsSearchHint'.tr(),
                      hintStyle: TextStyle(fontSize: 12.5.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      prefixIcon: Container(
                        margin: EdgeInsets.all(8.w),
                        width: 36.w, height: 36.w,
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)),
                        child: Icon(Icons.search_rounded, size: 18.sp, color: AppTheme.primaryColor),
                      ),
                      suffixIcon: _query.isEmpty ? null : IconButton(icon: Icon(Icons.close_rounded, size: 18.sp), onPressed: () { _searchController.clear(); setState(() => _query = ''); }),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                // شريط الفئات
                SizedBox(
                  height: 36.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, i) {
                      final cat = categories.elementAt(i);
                      final selected = cat == _categoryFilter;
                      return ChoiceChip(
                        label: Text(cat, style: TextStyle(fontSize: 11.5.sp, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
                        selected: selected,
                        onSelected: (_) => setState(() => _categoryFilter = cat),
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        side: BorderSide(color: selected ? AppTheme.primaryColor : const Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        showCheckmark: false,
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 0),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverToBoxAdapter(child: _buildNoResults(context))
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final product = filtered[index];
                return _ProductCard(product: product, onTap: () => _openForm(context, product: product))
                    .animate(delay: (40 * index).ms, effects: const [])
                    .fadeIn(duration: 320.ms)
                    .slideY(begin: 0.06, end: 0);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int count, double inventoryValue, int lowStockCount) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 188.h,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D2A86), Color(0xFF1A4FD6), Color(0xFF4A7BFF)]),
          ),
          child: Stack(
            children: [
              Positioned(top: -40.h, left: -30.w, child: Container(width: 140.w, height: 140.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
              Positioned(bottom: -30.h, right: -20.w, child: Container(width: 180.w, height: 180.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 12.h),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text('productsTitle'.tr(), style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(height: 2.h),
                          Text('${count} منتج في المخزون', style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        SizedBox(width: 10.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.inventory_2_rounded, size: 12.sp, color: Colors.white),
                            SizedBox(width: 5.w),
                            Text('productsCount'.tr(args: ['$count']), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                          ]),
                        ),
                      ]),
                    ),
                    SizedBox(height: 10.h),
                    Row(children: [
                      Expanded(child: _headerGlass(icon: Icons.payments_rounded, label: 'productsInventoryValue'.tr(), value: '${_formatPrice(inventoryValue)} ${'currencyEGP'.tr()}')),
                      SizedBox(width: 10.w),
                      Expanded(child: _headerGlass(icon: Icons.warning_amber_rounded, label: 'productsLowStock'.tr(), value: lowStockCount > 0 ? '$lowStockCount' : '0', danger: lowStockCount > 0)),
                    ]),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerGlass({required IconData icon, required String label, required String value, bool danger = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
      child: Row(children: [
        Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: danger ? const Color(0xFFFFD54F) : Colors.white)),
        SizedBox(width: 8.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: danger ? const Color(0xFFFFD54F) : Colors.white)),
        ])),
      ]),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomScrollView(slivers: [
      _buildHeader(context, 0, 0, 0),
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 110.w, height: 110.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.10), const Color(0xFF7C4DFF).withValues(alpha: 0.10)]),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.category_outlined, size: 52.sp, color: Theme.of(context).colorScheme.primary),
              ),
              SizedBox(height: 18.h),
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
                child: Column(children: [
                  Text('productsEmpty'.tr(), style: TextStyle(fontSize: 16.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  SizedBox(height: 8.h),
                  Text('productsEmptyHint'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, height: 1.6, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
                  SizedBox(height: 18.h),
                  SizedBox(width: double.infinity, height: 48.h, child: FilledButton.icon(onPressed: () => _openForm(context), style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))), icon: const Icon(Icons.add_rounded), label: Text('productsAdd'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)))),
                ]),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildNoResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 0),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
      child: Column(children: [
        Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle), child: Icon(Icons.search_off_rounded, size: 28.sp, color: const Color(0xFF94A3B8))),
        SizedBox(height: 12.h),
        Text('productsNoResults'.tr(), style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        SizedBox(height: 6.h),
        Text('جرّب كلمة بحث أخرى أو غيّر الفلتر', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
      ]),
    );
  }

  Widget _buildFailure(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 28.w), child: Container(padding: EdgeInsets.all(22.w), decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFEF2F2), shape: BoxShape.circle), child: Icon(Icons.cloud_off_rounded, size: 28.sp, color: const Color(0xFFE11D48))),
      SizedBox(height: 14.h),
      Text('productsLoadFailed'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      SizedBox(height: 16.h),
      SizedBox(width: double.infinity, height: 46.h, child: FilledButton.icon(onPressed: () => context.read<ProductsCubit>().init(), style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))), icon: const Icon(Icons.refresh_rounded, size: 18), label: Text('productsRetry'.tr(), style: TextStyle(fontWeight: FontWeight.w700)))),
    ]))));
  }

  Future<void> _openForm(BuildContext context, {Product? product}) async {
    final cubit = context.read<ProductsCubit>();
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProductFormView(cubit: cubit, product: product)));
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ProductThumb(product: product),
            SizedBox(width: 12.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                if (product.isOutOfStock) _badge('productsOutOfStock'.tr(), const Color(0xFFE11D48), Icons.block_rounded)
                else if (product.isLowStock) _badge('productsLow'.tr(), const Color(0xFFF59E0B), Icons.warning_amber_rounded),
              ]),
              SizedBox(height: 6.h),
              if (product.category.isNotEmpty || product.code.isNotEmpty)
                Row(children: [
                  if (product.category.isNotEmpty) Flexible(child: _chip(context, Icons.category_rounded, product.category)),
                  if (product.category.isNotEmpty && product.code.isNotEmpty) SizedBox(width: 6.w),
                  if (product.code.isNotEmpty) Flexible(child: _chip(context, Icons.qr_code_rounded, product.code)),
                ]),
              if (product.category.isNotEmpty || product.code.isNotEmpty) SizedBox(height: 10.h),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('productsSalePrice'.tr(), style: TextStyle(fontSize: 10.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.h),
                  Text('${_formatPrice(product.price)} ${'currencyEGP'.tr()}', style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFF059669))),
                  if (product.costPrice > 0) Text('شراء ${_formatPrice(product.costPrice)}', style: TextStyle(fontSize: 10.sp, color: const Color(0xFF94A3B8))),
                ])),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                  decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                  child: Column(children: [
                    Text('productsStock'.tr(), style: TextStyle(fontSize: 9.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w700)),
                    SizedBox(height: 2.h),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      if (product.isLowStock) Icon(Icons.warning_amber_rounded, size: 12.sp, color: const Color(0xFFF59E0B)),
                      if (product.isLowStock) SizedBox(width: 3.w),
                      Text('${product.stock}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: product.isOutOfStock ? const Color(0xFFE11D48) : isDark ? Colors.white : const Color(0xFF0F172A))),
                    ]),
                  ]),
                ),
                SizedBox(width: 8.w),
                Container(width: 30.w, height: 30.w, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(Icons.chevron_left_rounded, size: 18.sp, color: AppTheme.primaryColor)),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11.sp, color: const Color(0xFF64748B)),
        SizedBox(width: 4.w),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
      ]),
    );
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.18))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10.sp, color: color),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final Product product;
  const _ProductThumb({required this.product});
  @override
  Widget build(BuildContext context) {
    final hasImage = product.imageUrl.isNotEmpty;
    final placeholder = Container(
      width: 66.w, height: 66.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryColor.withValues(alpha: 0.12), const Color(0xFF7C4DFF).withValues(alpha: 0.12)]),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.08)),
      ),
      child: Icon(Icons.inventory_2_rounded, size: 26.sp, color: AppTheme.primaryColor.withValues(alpha: 0.9)),
    );
    if (!hasImage) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Image.network(product.imageUrl, width: 66.w, height: 66.w, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder, loadingBuilder: (context, child, progress) => progress == null ? child : placeholder),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 40.w, height: 40.w, child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryColor)),
      SizedBox(height: 12.h),
      Text('جاري تحميل المنتجات...', style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]));
  }
}

String _formatPrice(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
