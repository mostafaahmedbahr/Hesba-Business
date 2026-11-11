import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../accounts/data/models/person_model.dart';

/// قسم اختياري في فورم البيع لربط الفاتورة بجهة اتصال (عميل).
///
/// يشبه نفس تجربة «إضافة مديونية»: حقلا اسم/هاتف مع اقتراحات الأشخاص
/// المحفوظين أثناء الكتابة، مع ملاحظة عند مطابقة رقم محفوظ. الاتنين
/// يُكتبان معًا أو يُتركان فاضيين — والقرار النهائي في الـ submit.
class SaleCustomerSection extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final List<PersonModel> persons;

  /// `true` عند اختيار "آجل" — يُظهر ملاحظة إن العميل مطلوب.
  final bool creditRequired;

  const SaleCustomerSection({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.persons,
    this.creditRequired = false,
  });

  @override
  State<SaleCustomerSection> createState() => _SaleCustomerSectionState();
}

class _SaleCustomerSectionState extends State<SaleCustomerSection> {
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_onFocusChange);
    _phoneFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onFocusChange);
    _phoneFocus.removeListener(_onFocusChange);
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  bool get _anyFilled =>
      widget.nameController.text.trim().isNotEmpty ||
      widget.phoneController.text.trim().isNotEmpty;

  bool get _showSuggestions =>
      _nameFocus.hasFocus || _phoneFocus.hasFocus;

  /// الاقتراحات المطابقة للنص المكتوب حاليًا (الاسم أو الرقم)،
  /// والعملاء أولًا — المورد فقط يظهر لو مفيش عميل مطابق.
  List<PersonModel> get _suggestions {
    final q = (_nameFocus.hasFocus
            ? widget.nameController.text
            : widget.phoneController.text)
        .trim();
    final source = q.isEmpty
        ? widget.persons
        : widget.persons.where((p) {
            final lower = q.toLowerCase();
            if (p.name.toLowerCase().contains(lower)) return true;
            final qPhone = PersonModel.normalizePhone(q);
            return qPhone.isNotEmpty && p.normalizedPhone.contains(qPhone);
          }).toList();
    final list = source.toList()
      ..sort((a, b) => (b.isCustomer ? 1 : 0).compareTo(a.isCustomer ? 1 : 0));
    return list.take(5).toList();
  }

  /// هل الرقم الحالي يطابق شخصًا محفوظًا؟
  PersonModel? get _exactMatch {
    final target = PersonModel.normalizePhone(widget.phoneController.text);
    if (target.isEmpty) return null;
    for (final p in widget.persons) {
      if (p.normalizedPhone == target) return p;
    }
    return null;
  }

  void _selectPerson(PersonModel p) {
    widget.nameController.text = p.name;
    widget.phoneController.text = p.phone;
    setState(() {});
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
  }

  void _clear() {
    widget.nameController.clear();
    widget.phoneController.clear();
    setState(() {});
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.ink;
    final exactMatch = _exactMatch;

    InputDecoration decoration({
      required String label,
      required String hint,
      required IconData icon,
    }) {
      final fill = isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC);
      OutlineInputBorder border(Color color, [double width = 1.4]) =>
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: color, width: width),
          );
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: EdgeInsets.all(8.w),
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 17.sp, color: AppTheme.primaryColor),
        ),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: border(isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
        focusedBorder: border(AppTheme.primaryColor, 1.6),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'saleCustomerTitle'.tr(),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.slateGray.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'saleCustomerOptional'.tr(),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slateGray,
                ),
              ),
            ),
            const Spacer(),
            if (_anyFilled)
              TextButton.icon(
                onPressed: _clear,
                icon: Icon(Icons.close_rounded, size: 15.sp),
                label: Text(
                  'saleCustomerClear'.tr(),
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size(0, 32.h),
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'saleCustomerHint'.tr(),
          style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray),
        ),
        if (widget.creditRequired) ...[
          SizedBox(height: 8.h),
          _InlineNote(
            icon: Icons.schedule_rounded,
            color: AppTheme.amberDeep,
            text: 'saleCreditHint'.tr(),
          ),
        ],
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
            ),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: widget.nameController,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                onChanged: (_) => setState(() {}),
                decoration: decoration(
                  label: 'saleCustomerNameLabel'.tr(),
                  hint: 'saleCustomerNameHint'.tr(),
                  icon: Icons.person_rounded,
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: widget.phoneController,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                onChanged: (_) => setState(() {}),
                decoration: decoration(
                  label: 'saleCustomerPhoneLabel'.tr(),
                  hint: '01xxxxxxxxx',
                  icon: Icons.call_rounded,
                ),
              ),
              if (_showSuggestions) ...[
                SizedBox(height: 8.h),
                _SuggestionsPanel(
                  persons: _suggestions,
                  isDark: isDark,
                  onSelect: _selectPerson,
                ),
              ] else if (exactMatch != null) ...[
                SizedBox(height: 8.h),
                _InlineNote(
                  icon: Icons.link_rounded,
                  color: AppTheme.successDark,
                  text: 'saleCustomerMatch'.tr(namedArgs: {'name': exactMatch.name}),
                ),
              ] else if (_anyFilled) ...[
                SizedBox(height: 8.h),
                _InlineNote(
                  icon: Icons.person_add_alt_1_rounded,
                  color: AppTheme.primaryColor,
                  text: 'saleCustomerNewPerson'.tr(),
                ),
              ],
            ],
          ),
        ),
      ],
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
          color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
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
                'saleCustomerNewPerson'.tr(),
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
                  'saleCustomerPickExisting'.tr(),
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
                      radius: 15.r,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        p.name.trim().isEmpty
                            ? '؟'
                            : p.name.trim().substring(0, 1),
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

/// شارة نوع جهة الاتصال (عميل / مورد / الاثنين).
class _PersonTypeChip extends StatelessWidget {
  final String type;
  const _PersonTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      PersonModel.typeSupplier => ('saleCustomerTypeSupplier'.tr(), AppTheme.violetDeep),
      PersonModel.typeBoth => ('saleCustomerTypeBoth'.tr(), AppTheme.amberDeep),
      _ => ('saleCustomerTypeCustomer'.tr(), AppTheme.primaryColor),
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

/// ملاحظة صغيرة (ربط / حفظ جديد).
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
