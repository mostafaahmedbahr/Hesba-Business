import '../../../../common_imports.dart';

/// ملخص المرتجع (hero برتقالي بالمسترد).
class ReturnSummary extends StatelessWidget {
  final double gross;
  final double discountRatio;
  final double allocatedDiscount;
  final double net;

  const ReturnSummary({
    super.key,
    required this.gross,
    required this.discountRatio,
    required this.allocatedDiscount,
    required this.net,
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
          colors: [Color(0xFF92400E), Color(0xFFF59E0B), Color(0xFFFBBF24)],
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.30), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(top: -30.h, left: -20.w, child: Container(width: 110.w, height: 110.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.10)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.assignment_return_rounded, size: 15.sp, color: Colors.white.withValues(alpha: 0.9)),
                SizedBox(width: 6.w),
                Text('المبلغ المسترد', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.90))),
              ]),
              SizedBox(height: 8.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      net.toStringAsFixed(net == net.roundToDouble() ? 0 : 2),
                      style: TextStyle(fontSize: 38.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1, letterSpacing: -1),
                    ),
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 5.h),
                      child: Text('ج.م', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.90))),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12.r)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('قبل الخصم ${gross.toStringAsFixed(2)}', style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w600)),
                    if (discountRatio > 0)
                      Text('خصم الفاتورة ${(discountRatio * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
