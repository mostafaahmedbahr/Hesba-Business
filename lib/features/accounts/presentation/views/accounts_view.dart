import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import '../../data/models/debt_model.dart';
import '../../data/repos/accounts_repo.dart';
import '../cubit/accounts_cubit.dart';
import '../states/accounts_state.dart';
import '../widgets/accounts_header.dart';
import '../widgets/add_debt_sheet.dart';
import '../widgets/debt_card.dart';
import '../widgets/filter_sheet.dart';
import 'debt_details_view.dart';

/// شاشة الحسابات — ذمم العملاء والموردين مع إجماليات Premium في الأعلى.
class AccountsView extends StatelessWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountsCubit(repo: sl())..init(),
      child: const _AccountsBody(),
    );
  }
}

class _AccountsBody extends StatelessWidget {
  const _AccountsBody();

  /// يفتح نموذج إضافة مديونية (مع بوابة الاشتراك).
  Future<void> _openAddSheet(BuildContext context) async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    final cubit = context.read<AccountsCubit>();
    final snapshot = cubit.state;
    await showAddDebtSheet(
      context,
      initialTab: snapshot.activeTab,
      persons: snapshot.persons,
      onSubmit: ({
        required name,
        required phone,
        required partyType,
        required direction,
        required amount,
        required note,
      }) async {
        try {
          await sl<AccountsRepo>().addDebt(
            name: name,
            phone: phone,
            partyType: partyType,
            direction: direction,
            amount: amount,
            note: note,
          );
          if (context.mounted) {
            AppToast.success(context, 'تم حفظ المديونية بنجاح');
          }
          return null;
        } catch (e) {
          return e.toString().replaceAll('Exception: ', '');
        }
      },
    );
  }

  void _openDetails(BuildContext context, DebtModel debt) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DebtDetailsView(debt: debt)),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    HapticFeedback.lightImpact();
    final cubit = context.read<AccountsCubit>();
    final s = cubit.state;
    await showAccountsFilterSheet(
      context,
      statusFilter: s.statusFilter,
      dateFrom: s.dateFrom,
      dateTo: s.dateTo,
      onApply: (status, from, to) {
        cubit.setStatusFilter(status);
        cubit.setDateFrom(from);
        cubit.setDateTo(to);
      },
      onClear: cubit.clearFilters,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountsCubit, AccountsState>(
      listener: (context, state) {
        if (state.status == AccountsStatus.failure &&
            state.debts.isEmpty &&
            state.errorMessage != null) {
          AppToast.error(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        final cubit = context.read<AccountsCubit>();
        final visible = state.visibleDebts;
        final searching = state.searchQuery.trim().isNotEmpty;
        final filtering = state.hasActiveFilter;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'accounts_fab',
            onPressed: () => _openAddSheet(context),
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'مديونية جديدة',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
            ),
          ),
          body: RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () => cubit.refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // الهيدر (إجمالي ليّا / عليّ + الصافي + زرار الإضافة).
                AccountsHeader(
                  receivableTotal: state.receivableTotal,
                  payableTotal: state.payableTotal,
                  openCount: state.openCount(AccountsTab.customer) +
                      state.openCount(AccountsTab.supplier),
                  onAdd: () => _openAddSheet(context),
                ),
                // التبويبات (عملاء / موردين).
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                    child: _AccountsTabs(
                      activeTab: state.activeTab,
                      customerOpen: state.openCount(AccountsTab.customer),
                      supplierOpen: state.openCount(AccountsTab.supplier),
                      onChanged: cubit.setTab,
                    ),
                  ),
                ),
                // البحث + الفلتر.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SearchField(
                            query: state.searchQuery,
                            onChanged: cubit.setSearch,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _FilterButton(
                          active: filtering,
                          onTap: () => _openFilterSheet(context),
                        ),
                      ],
                    ),
                  ),
                ),
                // شريط الفلاتر النشطة (لو موجود).
                if (filtering)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
                      child: _ActiveFilterBanner(
                        onClear: cubit.clearFilters,
                      ),
                    ),
                  ),
                // المحتوى.
                if (state.status == AccountsStatus.loading &&
                    state.debts.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _LoadingState(),
                  )
                else if (state.status == AccountsStatus.failure &&
                    state.debts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message: state.errorMessage,
                      onRetry: () => cubit.refresh(),
                    ),
                  )
                else if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: (searching || filtering)
                        ? _NoResultsState(
                            onClear: () {
                              cubit.setSearch('');
                              cubit.clearFilters();
                            },
                          )
                        : _EmptyState(
                            isSupplierTab:
                                state.activeTab == AccountsTab.supplier,
                            onAdd: () => _openAddSheet(context),
                          ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (itemCtx, i) {
                        final debt = visible[i];
                        return DebtCard(
                          debt: debt,
                          onTap: () => _openDetails(itemCtx, debt),
                        );
                      },
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

/// تبويبات عملاء / موردين مع عداد الحسابات المفتوحة.
class _AccountsTabs extends StatelessWidget {
  final AccountsTab activeTab;
  final int customerOpen;
  final int supplierOpen;
  final ValueChanged<AccountsTab> onChanged;

  const _AccountsTabs({
    required this.activeTab,
    required this.customerOpen,
    required this.supplierOpen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.mist,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'العملاء',
            icon: Icons.person_rounded,
            badge: customerOpen,
            selected: activeTab == AccountsTab.customer,
            onTap: () => onChanged(AccountsTab.customer),
          ),
          _TabButton(
            label: 'الموردين',
            icon: Icons.local_shipping_rounded,
            badge: supplierOpen,
            selected: activeTab == AccountsTab.supplier,
            onTap: () => onChanged(AccountsTab.supplier),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppTheme.darkSurface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17.sp,
                color: selected ? AppTheme.primaryColor : AppTheme.slateGray,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppTheme.primaryColor : AppTheme.slateGray,
                ),
              ),
              if (badge > 0) ...[
                SizedBox(width: 6.w),
                Container(
                  constraints: BoxConstraints(minWidth: 20.w),
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.danger.withValues(alpha: 0.12)
                        : AppTheme.mutedGray.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '$badge',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: selected ? AppTheme.danger : AppTheme.slateGray,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// حقل البحث في القائمة.
class _SearchField extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.query, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : Colors.white,
        hintText: 'ابحث بالاسم أو رقم الهاتف...',
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 19.sp,
          color: AppTheme.slateGray,
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.mutedGray,
        ),
      ),
    );
  }
}

/// زرار الفلتر مع نقطة حمراء لو فيه فلاتر مفعّلة.
class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.darkSurfaceAlt : Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: active
                  ? AppTheme.primaryColor
                  : (isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
              width: active ? 1.6 : 1.2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20.sp,
                color: active ? AppTheme.primaryColor : AppTheme.slateGray,
              ),
              if (active)
                PositionedDirectional(
                  top: 9.h,
                  end: 9.w,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط يظهر أعلى القائمة عند تفعيل فلاتر.
class _ActiveFilterBanner extends StatelessWidget {
  final VoidCallback onClear;

  const _ActiveFilterBanner({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_rounded,
            size: 15.sp,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: 6.w),
          const Expanded(
            child: Text(
              'الفلاتر مفعّلة — النتائج معروضة حسب اختيارك',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Text(
              'مسح',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryColor),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84.w,
              height: 84.w,
              decoration: BoxDecoration(
                color: AppTheme.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 38.sp,
                color: AppTheme.danger,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'تعذر تحميل الحسابات',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: AppTheme.danger,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message ?? 'حدث خطأ غير متوقع — تحقق من الاتصال وحاول مرة أخرى',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.slateGray,
                height: 1.5,
              ),
            ),
            SizedBox(height: 18.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    EdgeInsets.symmetric(horizontal: 22.w, vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final VoidCallback onClear;

  const _NoResultsState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64.sp,
              color: AppTheme.paleSlate,
            ),
            SizedBox(height: 14.h),
            Text(
              'لا توجد نتائج مطابقة',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: AppTheme.slateGray,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'جرّب كلمة أخرى أو امسح الفلاتر',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedGray,
              ),
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: onClear,
              child: const Text(
                'مسح البحث والفلاتر',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSupplierTab;
  final VoidCallback onAdd;

  const _EmptyState({required this.isSupplierTab, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96.w,
              height: 96.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSupplierTab
                      ? const [
                          AppTheme.violetDeep,
                          AppTheme.violetSoft,
                        ]
                      : const [
                          AppTheme.primaryColor,
                          AppTheme.brightBlue,
                        ],
                ),
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: (isSupplierTab
                            ? AppTheme.violetDeep
                            : AppTheme.primaryColor)
                        .withValues(alpha: 0.30),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                isSupplierTab
                    ? Icons.local_shipping_rounded
                    : Icons.person_rounded,
                size: 44.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              isSupplierTab
                  ? 'لا توجد حسابات موردين بعد'
                  : 'لا توجد مديونيات عملاء بعد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              isSupplierTab
                  ? 'سجّل أول مستحق لك أو عليك لمورد — وسيظهر هنا مع حالة السداد وسجل الدفعات.'
                  : 'سجّل أول مديونية لعميل — وسيظهر هنا مع حالة السداد وسجل الدفعات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.slateGray,
                height: 1.6,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة أول مديونية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
