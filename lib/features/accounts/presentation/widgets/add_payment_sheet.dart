import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../data/models/debt_model.dart';
import 'accounts_utils.dart';

/// يفتح Bottom Sheet تسجيل دفعة على مديونية — جزئي أو كامل.
///
/// [onSubmit] يرجع رسالة خطأ أو null عند النجاح.
Future<void> showAddPaymentSheet(
  BuildContext context, {
  required DebtModel debt,
  required Future<String?> Function(double amount, String note) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _AddPaymentSheet(debt: debt, onSubmit: onSubmit),
    ),
  );
}

class _AddPaymentSheet extends StatefulWidget {
  final DebtModel debt;
  final Future<String?> Function(double amount, String note) onSubmit;

  const _AddPaymentSheet({required this.debt, required this.onSubmit});

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _amountError;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _fillAll() {
    setState(() {
      _amountCtrl.text = widget.debt.remaining.toStringAsFixed(2);
      _amountError = null;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(
      _amountCtrl.text.trim().replaceAll(',', ''),
    );
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'أدخل مبلغًا أكبر من صفر');
      return;
    }
    if (amount > widget.debt.remaining + 0.0001) {
      setState(() => _amountError = 'الدفعة أكبر من المتبقي');
      return;
    }
    setState(() {
      _saving = true;
      _amountError = null;
    });
    final error = await widget.onSubmit(amount, _noteCtrl.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.ink;
    final debt = widget.debt;
    final isReceivable = debt.isReceivable;
    final accent = isReceivable ? AppTheme.primaryColor : AppTheme.danger;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // المقبض + العنوان.
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: AppTheme.paleSlate,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    child: Icon(
                      Icons.payments_rounded,
                      color: accent,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسجيل دفعة',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        Text(
                          debt.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slateGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppTheme.slateGray,
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              // ملخص الحساب: الأصل / المدفوع / المتبقي.
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
                  ),
                ),
                child: Row(
                  children: [
                    _SummaryCell(
                      label: 'الأصل',
                      value: moneyWithCurrency(debt.amount),
                      color: textColor,
                    ),
                    _SummaryDivider(),
                    _SummaryCell(
                      label: 'المدفوع',
                      value: moneyWithCurrency(debt.paidAmount),
                      color: AppTheme.successDark,
                    ),
                    _SummaryDivider(),
                    _SummaryCell(
                      label: 'المتبقي',
                      value: moneyWithCurrency(debt.remaining),
                      color: accent,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              // حقل المبلغ + زرار «دفع الكل».
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
                        hintText: '0',
                        errorText: _amountError,
                        errorStyle: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        prefixIcon: Icon(
                          Icons.payments_rounded,
                          size: 18.sp,
                          color: AppTheme.slateGray,
                        ),
                        suffixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              'ج.م',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.slateGray,
                              ),
                            ),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(
                            color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide:
                              BorderSide(color: AppTheme.primaryColor, width: 1.6),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 13.h,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // دفع الكل.
                  Material(
                    color: AppTheme.successDark.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14.r),
                    child: InkWell(
                      onTap: _fillAll,
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        height: 54.h,
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.done_all_rounded,
                              size: 16.sp,
                              color: AppTheme.successDark,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'دفع الكل',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.successDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // ملاحظة.
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
                  hintText: 'ملاحظة على الدفعة (اختياري)',
                  prefixIcon: Icon(
                    Icons.notes_rounded,
                    size: 18.sp,
                    color: AppTheme.slateGray,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 1.6),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  hintStyle: TextStyle(
                    fontSize: 11.5.sp,
                    color: AppTheme.mutedGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // زرار الحفظ.
              SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _saving
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'حفظ الدفعة',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                          ),
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

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCell({
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
          SizedBox(height: 3.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.sp,
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

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28.h,
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      color: AppTheme.hairline,
    );
  }
}
