import 'package:flutter/services.dart';

import '../../../../common_imports.dart';

/// اختيار الدفع (3 كروت بدل dropdown).
class PaymentMethodSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String get _normalized {
    if (value == 'wallet') return AppConstants.paymentMobileWallet;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final methods = [
      _Method(AppConstants.paymentCash, 'نقدي', Icons.money_rounded, const [Color(0xFF059669), Color(0xFF34D399)]),
      _Method(AppConstants.paymentCard, 'بطاقة', Icons.credit_card_rounded, const [Color(0xFF1A4FD6), Color(0xFF4A7BFF)]),
      _Method(AppConstants.paymentMobileWallet, 'محفظة', Icons.account_balance_wallet_rounded, const [Color(0xFF7C3AED), Color(0xFFA78BFA)]),
    ];
    return Row(
      children: [
        for (int i = 0; i < methods.length; i++) ...[
          Expanded(
            child: _PayCard(
              method: methods[i],
              selected: _normalized == methods[i].value,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(methods[i].value);
              },
            ),
          ),
          if (i < methods.length - 1) SizedBox(width: 10.w),
        ],
      ],
    );
  }
}

/// بيانات طريقة دفع واحدة.
class _Method {
  final String value;
  final String label;
  final IconData icon;
  final List<Color> gradient;
  const _Method(this.value, this.label, this.icon, this.gradient);
}

/// كارت طريقة دفع.
class _PayCard extends StatelessWidget {
  final _Method method;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _PayCard({required this.method, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: method.gradient) : null,
          color: selected ? null : (isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC)),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? Colors.transparent : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            width: selected ? 0 : 1.2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: method.gradient.first.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              method.icon,
              size: 22.sp,
              color: selected ? Colors.white : const Color(0xFF94A3B8),
            ),
            SizedBox(height: 6.h),
            Text(
              method.label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: selected ? Colors.white : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
