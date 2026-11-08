import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../common_imports.dart';
import '../../data/models/debt_model.dart';
import 'account_bits.dart';
import 'accounts_utils.dart';

/// كارت مديونية: الاسم والهاتف + المبلغ المتبقي + حالة السداد +
/// أزرار الاتصال وواتساب.
class DebtCard extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback onTap;

  const DebtCard({super.key, required this.debt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSupplier = debt.partyType == DebtParty.supplier;
    final isReceivable = debt.isReceivable;
    final isPaid = debt.status == DebtStatus.paid;
    final remainingColor =
        isPaid ? AppTheme.successDark : (isReceivable ? AppTheme.primaryColor : AppTheme.danger);

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF3),
            ),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PersonAvatar(
                    name: debt.displayName,
                    isSupplier: isSupplier,
                    size: 46,
                  ),
                  SizedBox(width: 10.w),
                  // الاسم + الهاتف (الضغط على الرقم يفتح خيارات التواصل).
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          debt.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppTheme.ink,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        InkWell(
                          onTap: () =>
                              showPhoneActionsSheet(context, debt.personPhone),
                          borderRadius: BorderRadius.circular(8.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.call_rounded,
                                  size: 12.sp,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    debt.personPhone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryColor,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppTheme.primaryColor
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            DirectionPill(isReceivable: isReceivable),
                            if (debt.createdAt != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 10.5.sp,
                                    color: AppTheme.mutedGray,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    DateFormat('d MMM', 'ar')
                                        .format(debt.createdAt!),
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.slateGray,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w),
                  // سقف عرض عمود المبلغ حتى يأخذ عمود الاسم مساحة مضمونة.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 125),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Text(
                        'المتبقي',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mutedGray,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          moneyWithCurrency(debt.remaining),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: remainingColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      DebtStatusBadge(status: debt.status),
                    ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // تقدم السداد + إجمالي المدفوع.
              PaymentProgress(ratio: debt.paidRatio, isReceivable: isReceivable),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'مدفوع: ${moneyWithCurrency(debt.paidAmount)} من ${moneyWithCurrency(debt.amount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slateGray,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 18.sp,
                    color: AppTheme.paleSlate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
