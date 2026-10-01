import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../data/repos/sales_repo.dart';
import '../cubit/sales_list_cubit.dart';
import '../cubit/sales_list_state.dart';
import '../widgets/sales_list_card.dart';
import '../widgets/sales_list_header.dart';
import '../widgets/sales_list_placeholders.dart';
import '../widgets/sales_list_search.dart';

/// شاشة المبيعات (عرض بس — اللوجيك في Cubit).
class SalesView extends StatelessWidget {
  const SalesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesListCubit(repo: sl<SalesRepo>())..bootstrap(),
      child: const _SalesBody(),
    );
  }
}

/// هيكل الشاشة (FAB + حالات + محتوى).
class _SalesBody extends StatelessWidget {
  const _SalesBody();

  /// يفتح إضافة بيع وينعش الداشبورد.
  Future<void> _goToAddSale(BuildContext context) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.pushNamed(context, AppRoutes.addSaleView);
    if (!context.mounted) return;
    if (result == true) {
      try {
        context.read<DashboardCubit>().refresh();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesListCubit, SalesListState>(
      builder: (context, state) {
        // بيحمل.
        if (state.status == SalesListStatus.initial ||
            state.status == SalesListStatus.loading) {
          return const Scaffold(body: SalesListLoading());
        }
        // مفيش محل.
        if (!state.hasShop) {
          return const SalesListNoShop();
        }
        // خطأ.
        if (state.status == SalesListStatus.failure && state.sales.isEmpty) {
          return Scaffold(body: SalesListError(message: state.errorMessage ?? 'حدث خطأ'));
        }
        final cubit = context.read<SalesListCubit>();
        // فاضي خالص: زرار واحد بس (بتاع الـ empty).
        if (state.sales.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(
              slivers: [
                const SalesListHeader(
                  count: 0,
                  totalValue: 0,
                  todayCount: 0,
                  todayValue: 0,
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SalesListEmpty(onAdd: () => _goToAddSale(context)),
                ),
              ],
            ),
          );
        }
        // فيه داتا.
        final filtered = state.filtered;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async => cubit.bootstrap(),
            child: CustomScrollView(
              slivers: [
                SalesListHeader(
                  count: state.sales.length,
                  totalValue: state.totalValue,
                  todayCount: state.todaySales.length,
                  todayValue: state.todayValue,
                  onAdd: () => _goToAddSale(context),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                    child: SalesListSearch(
                      query: state.searchQuery,
                      paymentFilter: state.paymentFilter,
                      onSearchChanged: cubit.setSearch,
                      onFilterChanged: cubit.setPaymentFilter,
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverToBoxAdapter(child: SalesListNoResults())
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemBuilder: (context, i) => SalesListCard(sale: filtered[i])
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

/// زرار "بيع جديد" العائم.
class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'sales_fab',
      onPressed: onTap,
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text('بيع جديد', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
    );
  }
}
