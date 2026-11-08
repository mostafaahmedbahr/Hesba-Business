import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/person_model.dart';
import '../states/accounts_state.dart';

/// نتيجة الإرسال من نموذج إضافة المديونية.
typedef AddDebtSubmit = Future<String?> Function({
  required String name,
  required String phone,
  required String partyType,
  required String direction,
  required double amount,
  required String note,
});

/// يفتح Bottom Sheet إضافة مديونية — أنيق، بسيط، ويدعم:
/// - اختيار نوع الطرف (عميل / مورد) داخل نفس النموذج.
/// - اتجاه العملية للموردين (عليّ فلوس / ليّا فلوس).
/// - اقتراح الأشخاص المسجلين أثناء الكتابة + منع التكرار بنفس الرقم.
/// - حفظ الاسم والرقم كجهة اتصال عند أول استخدام.
Future<void> showAddDebtSheet(
  BuildContext context, {
  required AccountsTab initialTab,
  required List<PersonModel> persons,
  required AddDebtSubmit onSubmit,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _AddDebtSheet(
        initialTab: initialTab,
        persons: persons,
        onSubmit: onSubmit,
        isDark: isDark,
      ),
    ),
  );
}

class _AddDebtSheet extends StatefulWidget {
  final AccountsTab initialTab;
  final List<PersonModel> persons;
  final AddDebtSubmit onSubmit;
  final bool isDark;

  const _AddDebtSheet({
    required this.initialTab,
    required this.persons,
    required this.onSubmit,
    required this.isDark,
  });

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  late AccountsTab _tab = widget.initialTab;
  String _direction = DebtDirection.receivable;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  String? _amountError;
  String? _nameError;
  String? _phoneError;
  bool _saving = false;

  bool get _isSupplier => _tab == AccountsTab.supplier;

  /// الاقتراحات المطابقة للنص المكتوب حاليًا (الاسم أو الرقم).
  List<PersonModel> get _suggestions {
    final q = (_nameFocus.hasFocus ? _nameCtrl.text : _phoneCtrl.text).trim();
    final source = q.isEmpty
        ? widget.persons
        : widget.persons.where((p) {
            final lower = q.toLowerCase();
            if (p.name.toLowerCase().contains(lower)) return true;
            final qPhone = PersonModel.normalizePhone(q);
            return qPhone.isNotEmpty && p.normalizedPhone.contains(qPhone);
          }).toList();
    int rank(PersonModel p) =>
        (_isSupplier ? p.isSupplier : p.isCustomer) ? 0 : 1;
    final list = source.toList()..sort((a, b) => rank(a).compareTo(rank(b)));
    return list.take(5).toList();
  }

  bool get _showSuggestions =>
      _nameFocus.hasFocus || _phoneFocus.hasFocus;

  /// هل الرقم الحالي يطابق شخصًا محفوظًا؟
  PersonModel? get _exactMatch {
    final target = PersonModel.normalizePhone(_phoneCtrl.text);
    if (target.isEmpty) return null;
    for (final p in widget.persons) {
      if (p.normalizedPhone == target) return p;
    }
    return null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _selectPerson(PersonModel p) {
    setState(() {
      _nameCtrl.text = p.name;
      _phoneCtrl.text = p.phone;
      _nameError = null;
      _phoneError = null;
    });
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final amount = double.tryParse(
      _amountCtrl.text.trim().replaceAll(',', ''),
    );

    setState(() {
      _nameError = name.isEmpty ? 'الاسم مطلوب' : null;
      // نفس تحقق التسجيل: موبايل مصري (010/011/012/015).
      _phoneError = Validators.egyptianPhone(phone);
      _amountError =
          (amount == null || amount <= 0) ? 'أدخل مبلغًا أكبر من صفر' : null;
    });
    if (_nameError != null || _phoneError != null || _amountError != null) {
      return;
    }

    setState(() => _saving = true);
    final error = await widget.onSubmit(
      name: name,
      phone: phone,
      partyType: _isSupplier ? DebtParty.supplier : DebtParty.customer,
      direction: _isSupplier ? _direction : DebtDirection.receivable,
      amount: amount!,
      note: _noteCtrl.text.trim(),
    );
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
    final isDark = widget.isDark;
    final surface = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.ink;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // المقبض + العنوان.
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 4.h),
              child: Column(
                children: [
                  Container(
                    width: 44.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: AppTheme.paleSlate,
                      borderRadius: BorderRadius.circular(2.r),
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
                          Icons.receipt_long_rounded,
                          color: AppTheme.primaryColor,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مديونية جديدة',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'التاريخ يُسجَّل تلقائيًا عند الحفظ',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
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
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
            // المحتوى القابل للتمرير.
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // نوع الطرف.
                    _SegmentedParty(
                      tab: _tab,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                    SizedBox(height: 12.h),
                    // اتجاه العملية (للموردين فقط).
                    if (_isSupplier) ...[
                      _DirectionSelector(
                        direction: _direction,
                        onChanged: (d) => setState(() => _direction = d),
                      ),
                      SizedBox(height: 14.h),
                    ],
                    // الاسم.
                    _SheetLabel(_isSupplier ? 'اسم المورد' : 'اسم العميل'),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: _nameCtrl,
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(
                        hint: _isSupplier ? 'اسم المورد' : 'اسم العميل',
                        icon: Icons.person_rounded,
                        errorText: _nameError,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // الهاتف.
                    _SheetLabel('رقم الهاتف'),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: _phoneCtrl,
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(
                        hint: '01xxxxxxxxx',
                        icon: Icons.call_rounded,
                        errorText: _phoneError,
                        isDark: isDark,
                      ),
                    ),
                    // قائمة الاقتراحات.
                    if (_showSuggestions) ...[
                      SizedBox(height: 8.h),
                      _SuggestionsPanel(
                        persons: _suggestions,
                        isDark: isDark,
                        onSelect: _selectPerson,
                      ),
                    ],
                    // تنبيه التكرار / الحفظ الجديد.
                    if (_exactMatch != null) ...[
                      SizedBox(height: 8.h),
                      _InlineNote(
                        icon: Icons.link_rounded,
                        color: AppTheme.successDark,
                        text:
                            'الرقم مسجّل باسم «${_exactMatch!.name}» — سيتم ربط المديونية بنفس جهة الاتصال.',
                      ),
                    ],
                    SizedBox(height: 12.h),
                    // المبلغ.
                    _SheetLabel('المبلغ المستحق'),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        hint: '0',
                        icon: Icons.payments_rounded,
                        errorText: _amountError,
                        isDark: isDark,
                        suffix: Padding(
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
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // ملاحظات.
                    _SheetLabel('ملاحظات (اختياري)'),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      minLines: 1,
                      decoration: _inputDecoration(
                        hint: 'مثال: بضاعة شهر نوفمبر، دفعة عربون...',
                        icon: Icons.notes_rounded,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(height: 18.h),
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
                                'حفظ المديونية',
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
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    String? errorText,
    Widget? suffix,
  }) {
    final fill = isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight;
    OutlineInputBorder border(Color color, [double width = 1.4]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      filled: true,
      fillColor: fill,
      hintText: hint,
      errorText: errorText,
      errorStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700),
      prefixIcon: Icon(icon, size: 18.sp, color: AppTheme.slateGray),
      suffixIcon: suffix,
      enabledBorder: border(
        isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
      ),
      focusedBorder: border(AppTheme.primaryColor, 1.6),
      errorBorder: border(AppTheme.errorColor),
      focusedErrorBorder: border(AppTheme.errorColor, 1.6),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      hintStyle: TextStyle(
        fontSize: 12.sp,
        color: AppTheme.mutedGray,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// عنوان صغير لحقل داخل النموذج.
class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w800,
        color: AppTheme.slateGray,
      ),
    );
  }
}

/// ملاحظة صغيرة داخل النموذج (ربط / حفظ جديد).
class _InlineNote extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InlineNote({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// اختيار نوع الطرف: عميل / مورد.
class _SegmentedParty extends StatelessWidget {
  final AccountsTab tab;
  final ValueChanged<AccountsTab> onChanged;

  const _SegmentedParty({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          _SegmentButton(
            label: 'عميل',
            icon: Icons.person_rounded,
            selected: tab == AccountsTab.customer,
            onTap: () => onChanged(AccountsTab.customer),
          ),
          _SegmentButton(
            label: 'مورد',
            icon: Icons.local_shipping_rounded,
            selected: tab == AccountsTab.supplier,
            onTap: () => onChanged(AccountsTab.supplier),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: selected ? AppTheme.primaryColor : AppTheme.slateGray,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppTheme.primaryColor : AppTheme.slateGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// اختيار اتجاه عملية المورد: «عليّ فلوس» / «ليّا فلوس».
class _DirectionSelector extends StatelessWidget {
  final String direction;
  final ValueChanged<String> onChanged;

  const _DirectionSelector({required this.direction, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DirectionCard(
            title: 'عليّ فلوس',
            subtitle: 'أدفع للمورد',
            icon: Icons.call_made_rounded,
            color: AppTheme.danger,
            selected: direction == DebtDirection.payable,
            onTap: () => onChanged(DebtDirection.payable),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _DirectionCard(
            title: 'ليّا فلوس',
            subtitle: 'أحصّل من المورد',
            icon: Icons.call_received_rounded,
            color: AppTheme.successDark,
            selected: direction == DebtDirection.receivable,
            onTap: () => onChanged(DebtDirection.receivable),
          ),
        ),
      ],
    );
  }
}

class _DirectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _DirectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.10)
              : (isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? color : (isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: selected ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(icon, size: 17.sp, color: color),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: selected ? color : (isDark ? Colors.white : AppTheme.ink),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slateGray,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 18.sp, color: color),
          ],
        ),
      ),
    );
  }
}

/// لوحة الاقتراحات أسفل حقلي الاسم/الرقم.
class _SuggestionsPanel extends StatelessWidget {
  final List<PersonModel> persons;
  final bool isDark;
  final ValueChanged<PersonModel> onSelect;

  const _SuggestionsPanel({
    required this.persons,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (persons.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded,
                size: 15.sp, color: AppTheme.primaryColor),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'شخص جديد — سيُحفظ اسمه ورقمه للاستخدام مستقبلًا',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slateGray,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
            child: Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 12.sp, color: AppTheme.mutedGray),
                SizedBox(width: 5.w),
                Text(
                  'مسجّلون من قبل — اختر بدلًا من الكتابة',
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.mutedGray,
                  ),
                ),
              ],
            ),
          ),
          ...persons.map(
            (p) => InkWell(
              onTap: () => onSelect(p),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16.r,
                      backgroundColor: AppTheme.primarySoft,
                      child: Text(
                        p.name.trim().isEmpty ? '؟' : p.name.trim().substring(0, 1),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppTheme.ink,
                            ),
                          ),
                          Text(
                            p.phone,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slateGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PersonTypeChip(type: p.type),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

/// شارة نوع الشخص (عميل / مورد / الاثنين).
class _PersonTypeChip extends StatelessWidget {
  final String type;
  const _PersonTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      PersonModel.typeSupplier => ('مورد', AppTheme.violetDeep),
      PersonModel.typeBoth => ('عميل ومورد', AppTheme.amberDeep),
      _ => ('عميل', AppTheme.primaryColor),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
