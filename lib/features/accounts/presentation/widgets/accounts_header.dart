import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import 'accounts_utils.dart';

/// هيدر الحسابات — Premium: AppBar مثبّت فوق تدرّج أزرق عميق،
/// مع بطاقتين زجاجيتين توضّحان «ليّا فلوس» و«عليّ فلوس» والصافي.
class AccountsHeader extends StatelessWidget {
  /// إجمالي المستحقات لصالح صاحب المحل (كل المديونيات receivable).
  final double receivableTotal;

  /// إجمالي المستحقات على صاحب المحل (كل المديونيات payable).
  final double payableTotal;

  /// عدد المديونيات المفتوحة (يليّا أو عليّ) في كل الأطراف.
  final int openCount;

  /// يفتح نموذج إضافة مديونية.
  final VoidCallback onAdd;

  const AccountsHeader({
    super.key,
    required this.receivableTotal,
    required this.payableTotal,
    required this.openCount,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final net = receivableTotal - payableTotal;
    final netPositive = net >= 0;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 296.h,
      backgroundColor: AppTheme.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      stretch: true,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'الحسابات',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF0F2D8A),
                AppTheme.primaryColor,
                Color(0xFF4A7BFF),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -62.h,
                right: -44.w,
                child: _Orb(size: 185.w, opacity: 0.13),
              ),
              Positioned(
                bottom: -74.h,
                left: -52.w,
                child: Container(
                  width: 205.w,
                  height: 205.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                top: 88.h,
                left: 52.w,
                child: _Orb(size: 76.w, opacity: 0.10),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 30.h, 16.w, 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          // عداد الحسابات المفتوحة.
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 12.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 5.w),
                                  Flexible(
                                    child: Text(
                                      openCount == 0
                                          ? 'لا توجد حسابات مفتوحة'
                                          : '$openCount حساب مفتوح',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // زرار إضافة مديونية.
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onAdd();
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 16.sp,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'مديونية جديدة',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // بطاقتا «ليّا / عليّ» الزجاجيتان.
                      Row(
                        children: [
                          Expanded(
                            child: _GlassStat(
                              label: 'ليّا فلوس',
                              hint: 'مستحقة ليك عند العملاء والموردين',
                              amount: receivableTotal,
                              icon: Icons.call_received_rounded,
                              accent: const Color(0xFF34D399),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _GlassStat(
                              label: 'عليّ فلوس',
                              hint: 'مستحقة للموردين عليك',
                              amount: payableTotal,
                              icon: Icons.call_made_rounded,
                              accent: const Color(0xFFFDA4AF),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      // الصافي.
                      Row(
                        children: [
                          Icon(
                            netPositive
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 13.sp,
                            color: netPositive
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFDA4AF),
                          ),
                          SizedBox(width: 5.w),
                          Flexible(
                            child: Text(
                              netPositive
                                  ? 'الصافي لصالحك: ${moneyWithCurrency(net)}'
                                  : 'الصافي عليك: ${moneyWithCurrency(-net)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ],
                      ),
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

/// بطاقة زجاجية صغيرة داخل الهيدر (ليّا / عليّ).
class _GlassStat extends StatelessWidget {
  final String label;
  final String hint;
  final double amount;
  final IconData icon;
  final Color accent;

  const _GlassStat({
    required this.label,
    required this.hint,
    required this.amount,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 13.sp, color: accent),
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 7.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              moneyWithCurrency(amount),
              style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.4,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

/// الدائرة الزخرفية في خلفية الهيدر.
class _Orb extends StatelessWidget {
  final double size;
  final double opacity;
  const _Orb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
