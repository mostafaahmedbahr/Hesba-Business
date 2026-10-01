import '../../../../common_imports.dart';
import '../../../expenses/data/repos/expenses_repo.dart';
import '../../../returns/data/repos/returns_repo.dart';
import '../../../sales/data/repos/sales_repo.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/reports_activity.dart';
import '../widgets/reports_charts.dart';
import '../widgets/reports_filters.dart';
import '../widgets/reports_header.dart';
import '../widgets/reports_loading.dart';
import '../widgets/reports_stats.dart';

/// شاشة التقارير (عرض بس — اللوجيك في Cubit).
class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportsCubit(
        salesRepo: sl<SalesRepo>(),
        returnsRepo: sl<ReturnsRepo>(),
        expensesRepo: sl<ExpensesRepo>(),
      )..bootstrap(),
      child: const _ReportsBody(),
    );
  }
}

/// هيكل الشاشة (حالات + محتوى).
class _ReportsBody extends StatelessWidget {
  const _ReportsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        // مفيش محل.
        if (!state.hasShop && state.status == ReportsStatus.failure) {
          return ReportsNoShop(message: state.errorMessage);
        }
        final cubit = context.read<ReportsCubit>();
        final loading = state.isFirstLoading && state.allSales.isEmpty;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async => cubit.bootstrap(),
            child: CustomScrollView(
              slivers: [
                ReportsHeader(state: state),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                    child: ReportsPeriodChips(
                      period: state.period,
                      onChanged: cubit.setPeriod,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (loading) ...[
                        const ReportsLoadingGrid(),
                      ] else ...[
                        ReportsTrendCard(state: state)
                            .animate()
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.05, end: 0),
                        SizedBox(height: 14.h),
                        ReportsSummaryGrid(state: state),
                        SizedBox(height: 14.h),
                        ReportsBalanceCard(state: state),
                        SizedBox(height: 14.h),
                        ReportsExpensesPie(state: state),
                        SizedBox(height: 14.h),
                        ReportsTopProducts(state: state),
                        SizedBox(height: 14.h),
                        ReportsRecentActivity(state: state),
                      ],
                    ]),
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
