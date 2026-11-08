import 'package:intl/intl.dart';

import '../../../../common_imports.dart';
import '../../data/models/debt_model.dart';

/// نتيجة تطبيق الفلاتر من الـ sheet.
typedef FiltersApply = void Function(
  DebtStatus? status,
  DateTime? dateFrom,
  DateTime? dateTo,
);

/// يفتح Bottom Sheet الفلاتر: حالة السداد + نطاق التاريخ.
Future<void> showAccountsFilterSheet(
  BuildContext context, {
  required DebtStatus? statusFilter,
  required DateTime? dateFrom,
  required DateTime? dateTo,
  required FiltersApply onApply,
  required VoidCallback onClear,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _FilterSheet(
      statusFilter: statusFilter,
      dateFrom: dateFrom,
      dateTo: dateTo,
      onApply: onApply,
      onClear: onClear,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final DebtStatus? statusFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final FiltersApply onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.statusFilter,
    required this.dateFrom,
    required this.dateTo,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  DebtStatus? _status;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _status = widget.statusFilter;
    _from = widget.dateFrom;
    _to = widget.dateTo;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_from ?? now) : (_to ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: isFrom ? 'من تاريخ' : 'إلى تاريخ',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null && _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
        if (_from != null && _from!.isAfter(picked)) _from = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.ink;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppTheme.primaryColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'تصفية الحسابات',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
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
              SizedBox(height: 16.h),
              // حالة السداد.
              Text(
                'حالة السداد',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slateGray,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _StatusChoice(
                    label: 'الكل',
                    selected: _status == null,
                    color: AppTheme.primaryColor,
                    onTap: () => setState(() => _status = null),
                  ),
                  _StatusChoice(
                    label: 'غير مدفوع',
                    selected: _status == DebtStatus.unpaid,
                    color: AppTheme.danger,
                    onTap: () => setState(() => _status = DebtStatus.unpaid),
                  ),
                  _StatusChoice(
                    label: 'سداد جزئي',
                    selected: _status == DebtStatus.partial,
                    color: AppTheme.amberDeep,
                    onTap: () => setState(() => _status = DebtStatus.partial),
                  ),
                  _StatusChoice(
                    label: 'مدفوع',
                    selected: _status == DebtStatus.paid,
                    color: AppTheme.successDark,
                    onTap: () => setState(() => _status = DebtStatus.paid),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // التاريخ.
              Text(
                'تاريخ تسجيل المديونية',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slateGray,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'من',
                      value: _from,
                      onTap: () => _pickDate(isFrom: true),
                      onClear: () => setState(() => _from = null),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _DateButton(
                      label: 'إلى',
                      value: _to,
                      onTap: () => _pickDate(isFrom: false),
                      onClear: () => setState(() => _to = null),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              // أزرار التطبيق / المسح.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onClear();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.slateGray,
                        side: BorderSide(
                          color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: const Text(
                        'مسح الكل',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_status, _from, _to);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: const Text(
                        'تطبيق',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
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

class _StatusChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChoice({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppTheme.mist,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w800,
            color: selected ? color : AppTheme.slateGray,
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 17.sp,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedGray,
                      ),
                    ),
                    Text(
                      value == null
                          ? 'بدون تحديد'
                          : DateFormat('d MMM y', 'ar').format(value!),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: value == null
                            ? AppTheme.slateGray
                            : (isDark ? Colors.white : AppTheme.ink),
                      ),
                    ),
                  ],
                ),
              ),
              if (value != null)
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16.sp,
                    color: AppTheme.mutedGray,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
