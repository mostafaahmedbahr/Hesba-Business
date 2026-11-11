import 'package:easy_localization/easy_localization.dart';

import '../../../../common_imports.dart';
import '../../../../core/utils/phone_contact.dart';
import '../../data/repos/sales_repo.dart';
import '../cubit/customer_sales_cubit.dart';
import '../cubit/customer_sales_state.dart';
import '../widgets/sales_list_card.dart' show SalesListCard, dateTimeLabel;

/// شاشة «سجل مشتريات العميل»: كل فواتير جهة الاتصال إجمالياتها وتواريخها.
class CustomerSalesView extends StatelessWidget {
  final String personId;
  final String personName;
  final String personPhone;
  final String shopId;

  const CustomerSalesView({
    super.key,
    required this.personId,
    required this.personName,
    required this.personPhone,
    required this.shopId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerSalesCubit(repo: sl<SalesRepo>())
        ..init(
          shopId: shopId,
          personId: personId,
          personName: personName,
          personPhone: personPhone,
        ),
      child: const _CustomerSalesBody(),
    );
  }
}

class _CustomerSalesBody extends StatelessWidget {
  const _CustomerSalesBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: BlocBuilder<CustomerSalesCubit, CustomerSalesState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                _Header(
                  name: state.personName,
                  phone: state.personPhone,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                    child: _StatsRow(state: state),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 12.h),
                    child: Row(
                      children: [
                        Text(
                          'customerSalesInvoicesTitle'.tr(),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppTheme.ink,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '${state.count}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ..._contentSlivers(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(BuildContext context, CustomerSalesState state) {
    if (state.status == CustomerSalesStatus.loading ||
        state.status == CustomerSalesStatus.initial) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
      ];
    }
    if (state.status == CustomerSalesStatus.failure) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorState(
            message: state.errorMessage,
            onRetry: () => context.read<CustomerSalesCubit>().init(
                  shopId: state.shopId,
                  personId: state.personId,
                  personName: state.personName,
                  personPhone: state.personPhone,
                ),
          ),
        ),
      ];
    }
    if (state.sales.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: SalesListCard(
                sale: state.sales[index],
                fromCustomerHistory: true,
              ),
            ),
            childCount: state.sales.length,
          ),
        ),
      ),
    ];
  }
}

/// الهيدر (رجوع + بيانات العميل + أزرار التواصل).
class _Header extends StatelessWidget {
  final String name;
  final String phone;
  const _Header({required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    return SliverAppBar(
      pinned: true,
      expandedHeight: 168.h,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      stretch: true,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(Icons.arrow_back_rounded, size: 19.sp, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'customerSalesTitle'.tr(),
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF0A1F5C), AppTheme.primaryColor, Color(0xFF6D9BFF)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40.h,
                left: -30.w,
                child: Container(
                  width: 150.w,
                  height: 150.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -50.h,
                right: -40.w,
                child: Container(
                  width: 160.w,
                  height: 160.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF5A623).withValues(alpha: 0.13),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 52.h, 18.w, 14.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 30.r,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          trimmedName.isEmpty ? '؟' : trimmedName.substring(0, 1),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'customerSalesSince'.tr(),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              trimmedName.isEmpty ? '—' : trimmedName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            if (trimmedPhone.isNotEmpty)
                              Text(
                                trimmedPhone,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (trimmedPhone.isNotEmpty) ...[
                        _HeaderContactButton(
                          icon: Icons.call_rounded,
                          onTap: () => PhoneContact.call(context, trimmedPhone),
                        ),
                        SizedBox(width: 8.w),
                        _HeaderContactButton(
                          icon: Icons.chat_rounded,
                          onTap: () => PhoneContact.whatsapp(context, trimmedPhone),
                        ),
                        SizedBox(width: 8.w),
                        _HeaderContactButton(
                          icon: Icons.copy_rounded,
                          onTap: () => PhoneContact.copyPhone(context, trimmedPhone),
                        ),
                      ],
                    ],
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

/// زرار شفاف دائري في الهيدر (اتصال/واتساب/نسخ).
class _HeaderContactButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderContactButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(9.w),
          child: Icon(icon, size: 18.sp, color: Colors.white),
        ),
      ),
    );
  }
}

/// صف الإحصائيات: عدد الفواتير / إجمالي المشتريات / آخر فاتورة.
class _StatsRow extends StatelessWidget {
  final CustomerSalesState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final last = state.lastSaleAt;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            isDark: isDark,
            icon: Icons.receipt_long_rounded,
            color: AppTheme.primaryColor,
            value: '${state.count}',
            label: 'customerSalesCountLabel'.tr(),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _StatCard(
            isDark: isDark,
            icon: Icons.payments_rounded,
            color: AppTheme.successDark,
            value: state.totalPurchases.toStringAsFixed(
              state.totalPurchases == state.totalPurchases.roundToDouble() ? 0 : 2,
            ),
            label: 'customerSalesTotalLabel'.tr(),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _StatCard(
            isDark: isDark,
            icon: Icons.event_rounded,
            color: AppTheme.amberDeep,
            value: last == null ? '—' : dateTimeLabel(last),
            label: 'customerSalesLastLabel'.tr(),
            small: true,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool small;

  const _StatCard({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 17.sp, color: color),
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: small ? 12.sp : 17.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.ink,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedGray,
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة فارغة (لا توجد فواتير).
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76.w,
            height: 76.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 34.sp,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'customerSalesEmpty'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة خطأ مع إعادة محاولة.
class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40.sp, color: AppTheme.danger),
          SizedBox(height: 12.h),
          Text(
            message == null || message!.isEmpty ? 'customerSalesError'.tr() : message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.slateGray,
            ),
          ),
          SizedBox(height: 14.h),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('customerSalesRetry'.tr()),
          ),
        ],
      ),
    );
  }
}
