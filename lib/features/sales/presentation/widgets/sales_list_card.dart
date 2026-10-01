import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../data/models/sale_model.dart';
import '../cubit/sales_list_state.dart';

/// كارت فاتورة مختصر — ضغطة تفتح التفاصيل بأنيميشن.
class SalesListCard extends StatefulWidget {
  final SaleModel sale;
  const SalesListCard({super.key, required this.sale});

  @override
  State<SalesListCard> createState() => _SalesListCardState();
}

/// حالة الفتح/القفل للكارت.
class _SalesListCardState extends State<SalesListCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sale = widget.sale;
    final dateStr = DateFormat('dd/MM/yyyy  •  hh:mm a', 'ar').format(sale.createdAt);
    final idShort = sale.saleId.length >= 6 ? sale.saleId.substring(0, 6) : sale.saleId;
    final itemsLabel = sale.items.isEmpty
        ? 'فاتورة'
        : sale.items.length == 1
            ? sale.items.first.productName
            : '${sale.items.first.productName} +${sale.items.length - 1}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: _expanded
              ? AppTheme.primaryColor.withValues(alpha: 0.35)
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF3)),
        ),
        boxShadow: _expanded
            ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 10))]
            : AppTheme.cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expanded = !_expanded);
          },
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الملخص الدائم.
                Row(children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A4FD6), Color(0xFF6D9BFF)]),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(Icons.receipt_long_rounded, size: 22.sp, color: Colors.white),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(child: Text('فاتورة #$idShort', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                          if (sale.discount > 0) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                              decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8.r)),
                              child: Text('خصم', style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFFE11D48))),
                            ),
                          ],
                        ]),
                        SizedBox(height: 3.h),
                        Text('$itemsLabel • $dateStr', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(sale.total.toStringAsFixed(2), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: const Color(0xFF059669), height: 1)),
                      Text('ج.م', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                  SizedBox(width: 4.w),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(color: _expanded ? AppTheme.primaryColor.withValues(alpha: 0.10) : Colors.transparent, shape: BoxShape.circle),
                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 20.sp, color: _expanded ? AppTheme.primaryColor : const Color(0xFF94A3B8)),
                    ),
                  ),
                ]),
                // التفاصيل (تظهر بالضغطة).
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _Details(sale: sale, isDark: isDark),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 260),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// تفاصيل الفاتورة (أصناف + دفع + مرتجع).
class _Details extends StatelessWidget {
  final SaleModel sale;
  final bool isDark;
  const _Details({required this.sale, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE6EAF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sale.items.map((it) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Container(width: 7.w, height: 7.w, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF1A4FD6), Color(0xFF6D9BFF)]))),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '${it.productName} × ${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ),
                      Text('${it.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    ],
                  ),
                )),
            if (sale.discount > 0) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10.r)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('بعد خصم ${sale.discount.toStringAsFixed(0)} ج.م', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
                    Text('${sale.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFF059669))),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],
            Row(children: [
              SalesPaymentChip(method: sale.paymentMethod, isDark: isDark),
              const Spacer(),
              Text(dateTimeLabel(sale.createdAt), style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            ]),
            if (sale.note.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.notes_rounded, size: 13.sp, color: const Color(0xFF94A3B8)),
                SizedBox(width: 5.w),
                Expanded(child: Text(sale.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)))),
              ]),
            ],
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pushNamed(context, AppRoutes.addReturnView, arguments: {'originalSaleId': sale.saleId});
                },
                icon: Icon(Icons.assignment_return_rounded, size: 17.sp, color: const Color(0xFFD97706)),
                label: Text('مرتجع من الفاتورة', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFFD97706))),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                  backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.07),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// وقت مختصر (اليوم / أمس / تاريخ).
String dateTimeLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;
  final time = DateFormat('hh:mm a', 'ar').format(dt);
  if (diff == 0) return 'اليوم • $time';
  if (diff == 1) return 'أمس • $time';
  return '${DateFormat('dd/MM', 'ar').format(dt)} • $time';
}

/// شارة طريقة الدفع.
class SalesPaymentChip extends StatelessWidget {
  final String method;
  final bool isDark;
  const SalesPaymentChip({super.key, required this.method, required this.isDark});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (method) {
      case 'cash':
        icon = Icons.money_rounded;
        break;
      case 'card':
        icon = Icons.credit_card_rounded;
        break;
      case 'mobile_wallet':
      case 'wallet':
        icon = Icons.account_balance_wallet_rounded;
        break;
      default:
        icon = Icons.payment_rounded;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12.sp, color: const Color(0xFF64748B)),
        SizedBox(width: 5.w),
        Text(SalesListState.paymentLabel(method), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
      ]),
    );
  }
}
