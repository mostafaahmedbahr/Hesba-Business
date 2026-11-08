import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../common_imports.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import '../../data/models/debt_model.dart';
import '../cubit/debt_details_cubit.dart';
import '../states/debt_details_state.dart';
import '../widgets/account_bits.dart';
import '../widgets/accounts_utils.dart';
import '../widgets/add_payment_sheet.dart';

/// كشف الحساب — تفاصيل مديونية واحدة + سجل كل الحركات والدفعات.
///
/// لا يمكن حذف السجل الأصلي بعد السداد — للحفاظ على تاريخ المعاملات.
class DebtDetailsView extends StatelessWidget {
  final DebtModel debt;

  const DebtDetailsView({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebtDetailsCubit(repo: sl(), debtId: debt.id)
        ..init(initial: debt),
      child: const _DebtDetailsBody(),
    );
  }
}

class _DebtDetailsBody extends StatelessWidget {
  const _DebtDetailsBody();

  Future<void> _openPaymentSheet(BuildContext context) async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    final cubit = context.read<DebtDetailsCubit>();
    final debt = cubit.state.debt;
    if (debt == null) return;
    HapticFeedback.lightImpact();
    await showAddPaymentSheet(
      context,
      debt: debt,
      onSubmit: (amount, note) async {
        final ok = await cubit.addPayment(amount: amount, note: note);
        if (ok) {
          if (context.mounted) {
            AppToast.success(context, 'تم تسجيل الدفعة بنجاح');
          }
          return null;
        }
        return cubit.state.errorMessage ?? 'تعذر تسجيل الدفعة';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtDetailsCubit, DebtDetailsState>(
      listener: (context, state) {
        // أخطاء تسجيل الدفعة تظهر عبر الـ sheet نفسه — لا نكررها هنا.
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final debt = state.debt;

        if (state.status == DebtDetailsStatus.loading || debt == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final isSupplier = debt.partyType == DebtParty.supplier;
        final isReceivable = debt.isReceivable;
        final accent = isReceivable ? AppTheme.primaryColor : AppTheme.danger;
        final isPaid = debt.status == DebtStatus.paid;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryDark,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            title: const Text(
              'كشف الحساب',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'اتصال / واتساب',
                icon: const Icon(Icons.phone_in_talk_rounded),
                onPressed: () =>
                    showPhoneActionsSheet(context, debt.personPhone),
              ),
            ],
          ),
          // زرار تسجيل الدفعة ثابت أسفل الشاشة.
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
              child: SizedBox(
                height: 52.h,
                child: isPaid
                    ? ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.verified_rounded),
                        label: const Text('الحساب مسدد بالكامل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successDark,
                          disabledBackgroundColor:
                              AppTheme.successDark.withValues(alpha: 0.85),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _openPaymentSheet(context),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          'تسجيل دفعة — متبقي ${moneyWithCurrency(debt.remaining)}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          body: CustomScrollView(
              slivers: [
                // بطاقة الشخص + الاتجاه.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                    child: _PersonHeader(
                      debt: debt,
                      isSupplier: isSupplier,
                    ),
                  ),
                ),
                // ملخص المبالغ + شريط التقدم.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                    child: _SummaryCard(debt: debt, accent: accent),
                  ),
                ),
                // عنوان سجل الحركات.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 18.h, 16.w, 8.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 16.sp,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'سجل الحركات',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color:
                                isDark ? Colors.white : AppTheme.ink,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${state.payments.length + 1}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            'لا يُحذف السجل بعد السداد',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.mutedGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // خط الزمن: المديونية الأصلية + كل دفعة.
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // الحركة الأصلية.
                      _TimelineTile(
                        icon: Icons.note_add_rounded,
                        iconColor: accent,
                        title: 'تسجيل المديونية',
                        amount: '+${moneyWithCurrency(debt.amount)}',
                        amountColor: accent,
                        date: debt.createdAt,
                        note: debt.note,
                        isFirst: true,
                      ),
                      // الدفعات من الأقدم للأحدث حسب زمن التسجيل —
                      // القائمة تأتي الأحدث أولًا فنعكسها للعرض الزمني.
                      ...state.payments.reversed.map(
                        (p) => _TimelineTile(
                          icon: Icons.payments_rounded,
                          iconColor: AppTheme.successDark,
                          title: 'دفعة',
                          amount: '-${moneyWithCurrency(p.amount)}',
                          amountColor: AppTheme.successDark,
                          date: p.createdAt,
                          note: p.note,
                        ),
                      ),
                      // شارة اكتمال السداد.
                      if (isPaid)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: AppTheme.successDark
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 17.sp,
                                  color: AppTheme.successDark,
                                ),
                                SizedBox(width: 7.w),
                                Text(
                                  'تم سداد الحساب بالكامل',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.successDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ],
          ),
        );
      },
    );
  }
}

/// بطاقة الشخص أعلى كشف الحساب.
class _PersonHeader extends StatelessWidget {
  final DebtModel debt;
  final bool isSupplier;

  const _PersonHeader({required this.debt, required this.isSupplier});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF3),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          PersonAvatar(
            name: debt.displayName,
            isSupplier: isSupplier,
            size: 58,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.ink,
                  ),
                ),
                SizedBox(height: 4.h),
                InkWell(
                  onTap: () =>
                      showPhoneActionsSheet(context, debt.personPhone),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.call_rounded,
                        size: 12.sp,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        debt.personPhone,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    // نوع الطرف.
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: (isSupplier
                                ? AppTheme.violetDeep
                                : AppTheme.primaryColor)
                            .withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        isSupplier ? 'مورد' : 'عميل',
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w900,
                          color: isSupplier
                              ? AppTheme.violetDeep
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    DirectionPill(isReceivable: debt.isReceivable),
                    DebtStatusBadge(status: debt.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة ملخص المبالغ (الأصل / المدفوع / المتبقي + نسبة السداد).
class _SummaryCard extends StatelessWidget {
  final DebtModel debt;
  final Color accent;

  const _SummaryCard({required this.debt, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = (debt.paidRatio * 100).round();
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? const [Color(0xFF1E2A44), Color(0xFF151D2F)]
              : const [Color(0xFFFFFFFF), Color(0xFFF6F8FC)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF3),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SummaryStat(
                label: 'المبلغ الأصلي',
                value: moneyWithCurrency(debt.amount),
                color: isDark ? Colors.white : AppTheme.ink,
              ),
              _VDivider(),
              _SummaryStat(
                label: 'المدفوع',
                value: moneyWithCurrency(debt.paidAmount),
                color: AppTheme.successDark,
              ),
              _VDivider(),
              _SummaryStat(
                label: 'المتبقي',
                value: moneyWithCurrency(debt.remaining),
                color: debt.status == DebtStatus.paid
                    ? AppTheme.successDark
                    : accent,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // نسبة السداد.
          Row(
            children: [
              Text(
                'نسبة السداد',
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slateGray,
                ),
              ),
              const Spacer(),
              Text(
                '$pct٪',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          PaymentProgress(ratio: debt.paidRatio, isReceivable: debt.isReceivable),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedGray,
            ),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      color: AppTheme.hairline,
    );
  }
}

/// عنصر واحد في خط الزمن (المديونية الأصلية أو دفعة).
class _TimelineTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String amount;
  final Color amountColor;
  final DateTime? date;
  final String note;
  final bool isFirst;

  const _TimelineTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.amount,
    required this.amountColor,
    required this.date,
    this.note = '',
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الأيقونة + الخط الرأسي.
          Column(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(icon, size: 17.sp, color: iconColor),
              ),
              Expanded(
                child: Container(
                  width: 2.w,
                  margin: EdgeInsets.symmetric(vertical: 4.h),
                  color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
                ),
              ),
            ],
          ),
          SizedBox(width: 10.w),
          // محتوى الحركة.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Container(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppTheme.ink,
                            ),
                          ),
                        ),
                        Text(
                          amount,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    if (date != null)
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 11.sp,
                            color: AppTheme.mutedGray,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            DateFormat('d MMM y — hh:mm a', 'ar').format(date!),
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slateGray,
                            ),
                          ),
                        ],
                      ),
                    if (note.trim().isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 9.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkSurfaceAlt
                              : AppTheme.canvasLight,
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.slateGray,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
