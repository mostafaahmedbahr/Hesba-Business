import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../sales/data/models/sale_model.dart';

/// كارت صنف مرتجع (تحديد + stepper كمية + مسترد).
class ReturnItemCard extends StatelessWidget {
  final SaleItemModel item;
  final bool selected;
  final bool returnable;
  final double maxQty;
  final double alreadyReturned;
  final double discountRatio;
  final TextEditingController qtyController;
  final ValueChanged<bool> onSelect;
  final VoidCallback onQtyChanged;

  const ReturnItemCard({
    super.key,
    required this.item,
    required this.selected,
    required this.returnable,
    required this.maxQty,
    required this.alreadyReturned,
    required this.discountRatio,
    required this.qtyController,
    required this.onSelect,
    required this.onQtyChanged,
  });

  /// يزود / ينقص كمية الإرجاع.
  void _step(double delta) {
    final current = double.tryParse(qtyController.text) ?? 0;
    var next = current + delta;
    if (next < 0.5) next = 0.5;
    if (next > maxQty) next = maxQty;
    qtyController.text = next.toStringAsFixed(next % 1 == 0 ? 0 : 1);
    onQtyChanged();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qty = double.tryParse(qtyController.text) ?? 0;
    final lineNet = qty * item.unitPrice * (1 - discountRatio);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: !returnable
            ? (isDark ? AppTheme.darkSurfaceAlt.withValues(alpha: 0.5) : const Color(0xFFF1F5F9))
            : (isDark ? AppTheme.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: selected
              ? const Color(0xFFF59E0B)
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.16), blurRadius: 14, offset: const Offset(0, 6))]
            : AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Checkbox مخصص.
              InkWell(
                onTap: returnable ? () => onSelect(!selected) : null,
                borderRadius: BorderRadius.circular(10.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)])
                        : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: selected ? Colors.transparent : const Color(0xFFCBD5E1),
                      width: 1.6,
                    ),
                  ),
                  child: selected
                      ? Icon(Icons.check_rounded, size: 17.sp, color: Colors.white)
                      : null,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    SizedBox(height: 3.h),
                    Text(
                      'مباع: ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} • مرتجع قبل كده: ${alreadyReturned.toStringAsFixed(alreadyReturned % 1 == 0 ? 0 : 1)} • متاح: ${maxQty.toStringAsFixed(maxQty % 1 == 0 ? 0 : 1)}',
                      style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                    if (!returnable)
                      Padding(
                        padding: EdgeInsets.only(top: 3.h),
                        child: Text('تم إرجاع كل الكمية بالفعل', style: TextStyle(fontSize: 11.sp, color: const Color(0xFFE11D48), fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10.r)),
                child: Text('${item.unitPrice.toStringAsFixed(item.unitPrice % 1 == 0 ? 0 : 2)} ج.م', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
              ),
            ],
          ),
          // الكمية + المسترد (لو متحدد).
          if (selected && returnable) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Row(
                children: [
                  _StepBtn(icon: Icons.remove_rounded, onTap: () => _step(-1)),
                  Expanded(
                    child: TextFormField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
                      validator: (v) {
                        if (!selected) return null;
                        final q = double.tryParse(v ?? '');
                        if (q == null || q <= 0) return '!';
                        if (q > maxQty) return 'الحد $maxQty';
                        return null;
                      },
                      onChanged: (_) => onQtyChanged(),
                    ),
                  ),
                  _StepBtn(icon: Icons.add_rounded, onTap: () => _step(1)),
                  SizedBox(width: 10.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20.r)),
                    child: Text(
                      '${lineNet.toStringAsFixed(2)} ج.م',
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// زرار + / - للكمية.
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9.r),
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: Icon(icon, size: 16.sp, color: const Color(0xFFD97706)),
      ),
    );
  }
}
