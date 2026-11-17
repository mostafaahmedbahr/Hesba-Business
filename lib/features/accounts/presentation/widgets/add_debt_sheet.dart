import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/person_model.dart';
import '../states/accounts_state.dart';
import 'add_debt/direction_selector.dart';
import 'add_debt/inline_note.dart';
import 'add_debt/save_button.dart';
import 'add_debt/segmented_party.dart';
import 'add_debt/sheet_header.dart';
import 'add_debt/sheet_label.dart';
import 'add_debt/suggestions_panel.dart';

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
            AddDebtSheetHeader(isDark: isDark),
            Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
            // المحتوى القابل للتمرير.
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // نوع الطرف.
                    AddDebtSegmentedParty(
                      tab: _tab,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                    SizedBox(height: 12.h),
                    // اتجاه العملية (للموردين فقط).
                    if (_isSupplier) ...[
                      AddDebtDirectionSelector(
                        direction: _direction,
                        onChanged: (d) => setState(() => _direction = d),
                      ),
                      SizedBox(height: 14.h),
                    ],
                    // الاسم.
                    AddDebtSheetLabel(_isSupplier ? 'اسم المورد' : 'اسم العميل'),
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
                    const AddDebtSheetLabel('رقم الهاتف'),
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
                      AddDebtSuggestionsPanel(
                        persons: _suggestions,
                        isDark: isDark,
                        onSelect: _selectPerson,
                      ),
                    ],
                    // تنبيه التكرار / الحفظ الجديد.
                    if (_exactMatch != null) ...[
                      SizedBox(height: 8.h),
                      AddDebtInlineNote(
                        icon: Icons.link_rounded,
                        color: AppTheme.successDark,
                        text:
                            'الرقم مسجّل باسم «${_exactMatch!.name}» — سيتم ربط المديونية بنفس جهة الاتصال.',
                      ),
                    ],
                    SizedBox(height: 12.h),
                    // المبلغ.
                    const AddDebtSheetLabel('المبلغ المستحق'),
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
                    const AddDebtSheetLabel('ملاحظات (اختياري)'),
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
                    AddDebtSaveButton(saving: _saving, onPressed: _submit),
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
