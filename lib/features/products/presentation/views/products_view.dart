import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';
import '../../data/repos/products_repo.dart';
import '../cubit/products_cubit.dart';
import '../states/products_state.dart';
import '../widgets/product_card.dart';
import '../widgets/product_list_header.dart';
import '../widgets/product_placeholders.dart';
import '../widgets/product_search_bar.dart';
import 'product_form_view.dart';

/// شاشة المنتجات (عرض بس — اللوجيك في Cubit).
class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductsCubit(repo: sl<ProductsRepo>())..init(),
      child: const _ProductsBody(),
    );
  }
}

/// هيكل الشاشة (FAB + حالات + محتوى).
class _ProductsBody extends StatelessWidget {
  const _ProductsBody();

  /// يفتح فورم إضافة/تعديل.
  Future<void> _openForm(BuildContext context, {Product? product}) async {
    final cubit = context.read<ProductsCubit>();
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProductFormView(cubit: cubit, product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        // بيحمل.
        if (state.status == ProductsStatus.loading) {
          return const Scaffold(body: ProductListLoading());
        }
        // خطأ.
        if (state.status == ProductsStatus.failure) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: ProductListFailure(onRetry: () => context.read<ProductsCubit>().init()),
          );
        }
        final cubit = context.read<ProductsCubit>();
        // فاضي خالص: زرار واحد بس.
        if (state.products.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(slivers: [
              ProductListHeader(count: 0, inventoryValue: 0, lowStockCount: 0),
              SliverFillRemaining(
                hasScrollBody: false,
                child: ProductListEmpty(onAdd: () => _openForm(context)),
              ),
            ]),
          );
        }
        // فيه داتا.
        final filtered = state.filtered;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async => cubit.init(),
            child: CustomScrollView(
              slivers: [
                ProductListHeader(
                  count: state.products.length,
                  inventoryValue: state.inventoryValue,
                  lowStockCount: state.lowStockCount,
                  onAdd: () => _openForm(context),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                    child: ProductSearchBar(
                      query: state.searchQuery,
                      categoryFilter: state.categoryFilter,
                      categories: state.categories,
                      onSearchChanged: cubit.setSearch,
                      onFilterChanged: cubit.setCategoryFilter,
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverToBoxAdapter(child: ProductListNoResults())
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, i) => ProductCard(
                        product: filtered[i],
                        onTap: () => _openForm(context, product: filtered[i]),
                      )
                          .animate(delay: (50 * i).ms)
                          .fadeIn(duration: 320.ms)
                          .slideY(begin: 0.06, end: 0),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
