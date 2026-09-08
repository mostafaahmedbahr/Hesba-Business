import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repos/products_repo.dart';
import '../cubit/products_cubit.dart';
import '../states/products_state.dart';
import 'product_form_view.dart';

const _headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    AppTheme.primaryColor,
    AppTheme.primaryLight,
    Color(0xFF7C4DFF),
  ],
);

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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
            backgroundColor: Theme.of(context).colorScheme.surface,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              elevation: 6,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'productsAdd'.tr(),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
            ),
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
    if (products.isEmpty) {
      return _buildEmptyState(context);
    }

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? products
        : products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(q) ||
                    p.code.toLowerCase().contains(q) ||
                    p.category.toLowerCase().contains(q),
              )
              .toList();

    double inventoryValue = 0;
    for (final p in filtered) {
      inventoryValue += p.costPrice * p.stock;
    }
    final lowStockCount = filtered.where((p) => p.isLowStock).length;

    return CustomScrollView(
      slivers: [
        _buildHeader(context, products.length, inventoryValue, lowStockCount),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'productsSearchHint'.tr(),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverToBoxAdapter(child: _buildNoResults(context))
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 110.h),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => SizedBox(height: 14.h),
              itemBuilder: (context, index) {
                final product = filtered[index];
                return _ProductCard(
                  product: product,
                  onTap: () => _openForm(context, product: product),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int count,
    double inventoryValue,
    int lowStockCount,
  ) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 150.h,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: _headerGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 44.h, 20.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'productsTitle'.tr(),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _headerPill(
                        icon: Icons.inventory_2_rounded,
                        label: 'productsCount'.tr(args: ['$count']),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _headerStat(
                          icon: Icons.payments_rounded,
                          label: 'productsInventoryValue'.tr(),
                          value:
                              '${_formatPrice(inventoryValue)} ${'currencyEGP'.tr()}',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _headerStat(
                          icon: Icons.warning_amber_rounded,
                          label: 'productsLowStock'.tr(),
                          value:
                              lowStockCount > 0 ? '$lowStockCount' : '0',
                          danger: lowStockCount > 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerPill({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat({
    required IconData icon,
    required String label,
    required String value,
    bool danger = false,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: danger
                ? const Color(0xFFFFB74D)
                : Colors.white,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color:
                        danger ? const Color(0xFFFFB74D) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildHeader(context, 0, 0, 0),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104.w,
                    height: 104.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.12),
                          const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.category_outlined,
                      size: 52.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'productsEmpty'.tr(),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'productsEmptyHint'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  FilledButton.icon(
                    onPressed: () => _openForm(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 14.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      'productsAdd'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 40.h),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 10.h),
          Text(
            'productsNoResults'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailure(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 14.h),
            Text(
              'productsLoadFailed'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: () => context.read<ProductsCubit>().init(),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('productsRetry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Product? product}) async {
    final cubit = context.read<ProductsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductFormView(cubit: cubit, product: product),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = this.product;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18.r,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductThumb(product: product),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (product.isOutOfStock)
                          _stockBadge(
                            context,
                            'productsOutOfStock'.tr(),
                            const Color(0xFFE53935),
                          )
                        else if (product.isLowStock)
                          _stockBadge(
                            context,
                            'productsLow'.tr(),
                            AppTheme.secondaryColor,
                          ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    if (product.category.isNotEmpty ||
                        product.code.isNotEmpty) ...[
                      Row(
                        children: [
                          if (product.category.isNotEmpty)
                            Flexible(
                              child: _chip(
                                context,
                                Icons.category_rounded,
                                product.category,
                              ),
                            ),
                          if (product.category.isNotEmpty &&
                              product.code.isNotEmpty)
                            SizedBox(width: 6.w),
                          if (product.code.isNotEmpty)
                            Flexible(
                              child: _chip(
                                context,
                                Icons.qr_code_rounded,
                                product.code,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'productsSalePrice'.tr(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${_formatPrice(product.price)} ${'currencyEGP'.tr()}',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'productsStock'.tr(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                if (product.isLowStock)
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 13.sp,
                                    color: AppTheme.secondaryColor,
                                  ),
                                SizedBox(width: 3.w),
                                Text(
                                  '${product.stock}',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                    color: product.isOutOfStock
                                        ? const Color(0xFFE53935)
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            product.isOutOfStock
                ? Icons.block_rounded
                : Icons.warning_amber_rounded,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final Product product;

  const _ProductThumb({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = product.imageUrl.isNotEmpty;

    final placeholder = Container(
      width: 62.w,
      height: 62.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.18),
            const Color(0xFF7C4DFF).withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        size: 28.sp,
        color: theme.colorScheme.primary,
      ),
    );

    if (!hasImage) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Image.network(
        product.imageUrl,
        width: 62.w,
        height: 62.w,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder;
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

String _formatPrice(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}