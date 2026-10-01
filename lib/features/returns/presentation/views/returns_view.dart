import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../data/repos/returns_repo.dart';
import '../cubit/returns_list_cubit.dart';
import '../cubit/returns_list_state.dart';
import '../widgets/returns_list_card.dart';
import '../widgets/returns_list_header.dart';
import '../widgets/returns_list_placeholders.dart';
import '../widgets/returns_list_search.dart';

/// شاشة المرتجعات (صفحة داخلية لوحدها — اللوجيك في Cubit).
class ReturnsView extends StatelessWidget {
  const ReturnsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReturnsListCubit(repo: sl<ReturnsRepo>())..bootstrap(),
      child: const _ReturnsBody(),
    );
  }
}

/// هيكل الشاشة (FAB + حالات + محتوى).
class _ReturnsBody extends StatelessWidget {
  const _ReturnsBody();

  /// يفتح إضافة مرتجع وينعش الداشبورد.
  Future<void> _goToAddReturn(BuildContext context) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.pushNamed(context, AppRoutes.addReturnView);
    if (!context.mounted) return;
    if (result == true) {
      try {
        context.read<DashboardCubit>().refresh();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReturnsListCubit, ReturnsListState>(
      builder: (context, state) {
        // بيحمل.
        if (state.status == ReturnsListStatus.initial ||
            state.status == ReturnsListStatus.loading) {
          return const Scaffold(body: ReturnsListLoading());
        }
        // مفيش محل.
        if (!state.hasShop) {
          return const ReturnsListNoShop();
        }
        // خطأ.
        if (state.status == ReturnsListStatus.failure && state.returns.isEmpty) {
          return Scaffold(body: ReturnsListError(message: state.errorMessage ?? 'حدث خطأ'));
        }
        final cubit = context.read<ReturnsListCubit>();
        // فاضي خالص: زرار واحد بس.
        if (state.returns.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(
              slivers: [
                const ReturnsListHeader(
                  count: 0,
                  totalValue: 0,
                  todayCount: 0,
                  todayValue: 0,
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ReturnsListEmpty(onAdd: () => _goToAddReturn(context)),
                ),
              ],
            ),
          );
        }
        // فيه داتا.
        final filtered = state.filtered;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'returns_fab',
            onPressed: () => _goToAddReturn(context),
            elevation: 0,
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text('مرتجع جديد', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
          ),
          body: RefreshIndicator(
            color: const Color(0xFFF59E0B),
            onRefresh: () async => cubit.bootstrap(),
            child: CustomScrollView(
              slivers: [
                ReturnsListHeader(
                  count: state.returns.length,
                  totalValue: state.totalValue,
                  todayCount: state.todayReturns.length,
                  todayValue: state.todayValue,
                  onAdd: () => _goToAddReturn(context),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                    child: ReturnsListSearch(
                      query: state.searchQuery,
                      reasonFilter: state.reasonFilter,
                      reasons: state.reasons,
                      onSearchChanged: cubit.setSearch,
                      onFilterChanged: cubit.setReasonFilter,
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverToBoxAdapter(child: ReturnsListNoResults())
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, i) => ReturnsListCard(ret: filtered[i]),
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
