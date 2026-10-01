import '../../../../common_imports.dart';

/// ملخص الفاتورة (كارت gradient بالإجمالي الكبير).
class SaleSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double total;
  final int itemsCount;

  const SaleSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.itemsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0A1F5C), Color(0xFF1A4FD6), Color(0xFF4A7BFF)],
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1A4FD6).withValues(alpha: 0.30), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(top: -30.h, left: -20.w, child: Container(width: 110.w, height: 110.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.receipt_long_rounded, size: 15.sp, color: Colors.white.withValues(alpha: 0.85)),
                SizedBox(width: 6.w),
                Text('ملخص الفاتورة', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.88))),
                const Spacer(),
                if (itemsCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20.r)),
                    child: Text('$itemsCount ${itemsCount == 1 ? 'صنف' : 'أصناف'}', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
              ]),
              SizedBox(height: 10.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      total.toStringAsFixed(total == total.roundToDouble() ? 0 : 2),
                      style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1, letterSpacing: -1),
                    ),
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 5.h),
                      child: Text('ج.م', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.88))),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12.r)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المجموع ${subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.88), fontWeight: FontWeight.w600)),
                    Text('الخصم -${discount.toStringAsFixed(2)}', style: TextStyle(fontSize: 11.sp, color: discount > 0 ? const Color(0xFFFFD1D1) : Colors.white.withValues(alpha: 0.88), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (discount > subtotal) ...[
                SizedBox(height: 8.h),
                Row(children: [
                  Icon(Icons.info_outline_rounded, size: 13.sp, color: const Color(0xFFFFD54F)),
                  SizedBox(width: 6.w),
                  Expanded(child: Text('الخصم أكبر من المجموع، هيتحسب مساوياً ليه', style: TextStyle(fontSize: 11.sp, color: const Color(0xFFFFD54F), fontWeight: FontWeight.w600))),
                ]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
