import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../data/models/sale_model.dart';
import '../cubit/sales_list_state.dart';

/// كارت فاتورة (أصناف + خصم + مرتجع).
class SalesListCard extends StatelessWidget {
  final SaleModel sale;
  const SalesListCard({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd/MM/yyyy  hh:mm a', 'ar').format(sale.createdAt);
    final idShort = sale.saleId.length >= 6 ? sale.saleId.substring(0, 6) : sale.saleId;
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: () {},
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _CardHeader(sale: sale, idShort: idShort, dateStr: dateStr, isDark: isDark),
            if (sale.items.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(height: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9)),
              SizedBox(height: 10.h),
              ...sale.items.map((it) => _ItemRow(
                    name: it.productName,
                    quantity: it.quantity,
                    total: it.total,
                    isDark: isDark,
                  )),
              if (sale.discount > 0) _DiscountBox(sale: sale, isDark: isDark),
            ],
            SizedBox(height: 12.h),
            Row(children: [
              SalesPaymentChip(method: sale.paymentMethod, isDark: isDark),
              const Spacer(),
              if (sale.discount > 0) _DiscountBadge(discount: sale.discount),
            ]),
            if (sale.note.isNotEmpty) ...[
              SizedBox(height: 10.h),
              _NoteBox(note: sale.note, isDark: isDark),
            ],
            SizedBox(height: 12.h),
            _ReturnButton(saleId: sale.saleId),
          ]),
        ),
      ),
    );
  }
}

/// أول الكارت (أيقونة + رقم + تاريخ + إجمالي).
class _CardHeader extends StatelessWidget {
  final SaleModel sale;
  final String idShort;
  final String dateStr;
  final bool isDark;
  const _CardHeader({required this.sale, required this.idShort, required this.dateStr, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 44.w, height: 44.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A4FD6), Color(0xFF4A7BFF)]), borderRadius: BorderRadius.circular(12.r)), child: Icon(Icons.receipt_long_rounded, size: 20.sp, color: Colors.white)),
      SizedBox(width: 12.w),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('فاتورة #$idShort', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        SizedBox(height: 2.h),
        Row(children: [Icon(Icons.access_time_rounded, size: 11.sp, color: const Color(0xFF94A3B8)), SizedBox(width: 4.w), Expanded(child: Text(dateStr, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis))]),
      ])),
      Container(padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.18))), child: Text('${sale.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFF059669)))),
    ]);
  }
}

/// سطر صنف (اسم × كمية + إجمالي).
class _ItemRow extends StatelessWidget {
  final String name;
  final double quantity;
  final double total;
  final bool isDark;
  const _ItemRow({required this.name, required this.quantity, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(children: [
              Container(width: 6.w, height: 6.w, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1A4FD6))),
              SizedBox(width: 8.w),
              Expanded(child: Text('$name × ${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)}', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ),
          Text('${total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}

/// بوكس تفاصيل الخصم.
class _DiscountBox extends StatelessWidget {
  final SaleModel sale;
  final bool isDark;
  const _DiscountBox({required this.sale, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('قبل الخصم', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))), Text('${sale.subtotal.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 11.sp, decoration: TextDecoration.lineThrough, color: const Color(0xFF64748B)))]),
          SizedBox(height: 6.h),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('الخصم', style: TextStyle(fontSize: 11.sp, color: const Color(0xFFE11D48))), Text('-${sale.discount.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFFE11D48)))]),
          Divider(height: 16.h, color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('المدفوع (دخل حسابك)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))), Text('${sale.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: const Color(0xFF059669)))]),
        ]),
      ),
    );
  }
}

/// شارة الخصم الصغيرة.
class _DiscountBadge extends StatelessWidget {
  final double discount;
  const _DiscountBadge({required this.discount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.14))),
      child: Text('خصم ${discount.toStringAsFixed(0)} ج.م', style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
    );
  }
}

/// بوكس الملاحظة.
class _NoteBox extends StatelessWidget {
  final String note;
  final bool isDark;
  const _NoteBox({required this.note, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.notes_rounded, size: 14.sp, color: const Color(0xFF94A3B8)), SizedBox(width: 6.w), Expanded(child: Text(note, style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))))]),
    );
  }
}

/// زرار مرتجع من الفاتورة.
class _ReturnButton extends StatelessWidget {
  final String saleId;
  const _ReturnButton({required this.saleId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: FilledButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, AppRoutes.addReturnView, arguments: {'originalSaleId': saleId});
        },
        icon: const Icon(Icons.assignment_return_rounded, size: 18),
        label: Text('إضافة مرتجع من هذه الفاتورة', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800)),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
      ),
    );
  }
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
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12.sp, color: const Color(0xFF64748B)),
        SizedBox(width: 5.w),
        Text(SalesListState.paymentLabel(method), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
      ]),
    );
  }
}
