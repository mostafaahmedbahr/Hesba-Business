import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';
import '../../data/models/expense_model.dart';
import '../widgets/expense_category_meta.dart';
import '../../../subscription/presentation/subscription_gate.dart';

/// شاشة إضافة/تعديل مصروف (هيدر حي + شريط حفظ ثابت).
class AddExpenseView extends StatefulWidget {
  final String? ownerId;
  final String? shopId;
  final ExpenseModel? expense;
  const AddExpenseView({super.key, this.ownerId, this.shopId, this.expense});
  @override
  State<AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<AddExpenseView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = '';
  DateTime _selectedDate = DateTime.now();
  String? _resolvedOwnerId;
  String? _resolvedShopId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _resolvedOwnerId = widget.ownerId;
    _resolvedShopId = widget.shopId;
    _isEditing = widget.expense != null;
    if (_isEditing && widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toStringAsFixed(widget.expense!.amount % 1 == 0 ? 0 : 2);
      _noteController.text = widget.expense!.note;
      _category = widget.expense!.category;
      _selectedDate = widget.expense!.date;
    }
    _resolveIds();
  }

  Future<void> _resolveIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_resolvedOwnerId == null || _resolvedOwnerId!.isEmpty) _resolvedOwnerId = uid;
    if (_resolvedShopId == null || _resolvedShopId!.isEmpty) {
      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          _resolvedShopId = doc.data()?['shopId'] as String?;
        } catch (_) {}
      }
    }
    if (mounted) setState(() {});
  }

  /// المبلغ الحالي (بعد تحويل الأرقام العربية).
  double get _amount => double.tryParse(_toLatin(_amountController.text.trim())) ?? 0;

  Future<void> _submit(BuildContext innerContext) async {
    if (!await SubscriptionGate.ensureCanModify(innerContext)) return;
    if (!_formKey.currentState!.validate()) return;
    if (_category.isEmpty) {
      AppToast.error(innerContext, 'اختر تصنيف المصروف');
      return;
    }
    // تأكد من حل الـ IDs لو لسه فاضية.
    if (_resolvedShopId == null || _resolvedShopId!.isEmpty || _resolvedOwnerId == null || _resolvedOwnerId!.isEmpty) {
      await _resolveIds();
    }
    final title = _titleController.text.trim();
    final amount = double.tryParse(_toLatin(_amountController.text.trim())) ?? 0;
    final note = _noteController.text.trim();
    HapticFeedback.lightImpact();
    if (_isEditing && widget.expense != null) {
      await innerContext.read<ExpensesCubit>().updateExpense(expenseId: widget.expense!.expenseId, ownerId: _resolvedOwnerId ?? '', shopId: _resolvedShopId ?? '', title: title, category: _category, amount: amount, note: note, date: _selectedDate);
    } else {
      await innerContext.read<ExpensesCubit>().addExpense(ownerId: _resolvedOwnerId ?? '', shopId: _resolvedShopId ?? '', title: title, category: _category, amount: amount, note: note, date: _selectedDate);
    }
  }

  String _toLatin(String input) => input
      .replaceAll('٠', '0').replaceAll('١', '1').replaceAll('٢', '2').replaceAll('٣', '3').replaceAll('٤', '4')
      .replaceAll('٥', '5').replaceAll('٦', '6').replaceAll('٧', '7').replaceAll('٨', '8').replaceAll('٩', '9')
      .replaceAll('۰', '0').replaceAll('۱', '1').replaceAll('۲', '2').replaceAll('۳', '3').replaceAll('۴', '4')
      .replaceAll('۵', '5').replaceAll('۶', '6').replaceAll('۷', '7').replaceAll('۸', '8').replaceAll('۹', '9');

  Future<void> _pickDate(BuildContext innerContext) async {
    final picked = await showDatePicker(context: innerContext, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)), locale: const Locale('ar'), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE11D48))), child: child!));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  void dispose() {
    _titleController.dispose(); _amountController.dispose(); _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => ExpensesCubit(expensesRepo: sl())..reset(),
      child: BlocListener<ExpensesCubit, ExpensesState>(
        listener: (ctx, state) {
          if (state.status == ExpensesStatus.success) {
            HapticFeedback.mediumImpact();
            AppToast.success(ctx, _isEditing ? 'تم تعديل المصروف بنجاح' : 'تم إضافة المصروف بنجاح');
            Navigator.pop(ctx, true);
          }
          if (state.status == ExpensesStatus.error) AppToast.error(ctx, state.errorMessage ?? 'حدث خطأ');
        },
        child: Builder(builder: (innerContext) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              top: false,
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    // هيدر gradient بالمبلغ الحي.
                    _AddHeader(amount: _amount, category: _category, date: _selectedDate, isEditing: _isEditing),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle('التصنيف', isDark: isDark),
                            SizedBox(height: 10.h),
                            Wrap(
                              spacing: 9.w,
                              runSpacing: 9.h,
                              children: [
                                for (final cat in AppConstants.expenseCategories)
                                  _CatChip(
                                    label: cat,
                                    icon: expenseCatIcon(cat),
                                    color: expenseCatColor(cat),
                                    selected: _category == cat,
                                    isDark: isDark,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _category = cat);
                                    },
                                  ),
                              ],
                            ),
                            if (_category.isEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 8.h, right: 4.w),
                                child: Text('اختار التصنيف الأول', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
                              ),
                            SizedBox(height: 20.h),

                            // المبلغ + العنوان.
                            _SectionTitle('التفاصيل', isDark: isDark),
                            SizedBox(height: 10.h),
                            Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(18.r),
                                border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                                boxShadow: AppTheme.cardShadow(context),
                              ),
                              child: Column(children: [
                                _BigAmountField(
                                  controller: _amountController,
                                  isDark: isDark,
                                  onChanged: () => setState(() {}),
                                  toLatin: _toLatin,
                                ),
                                SizedBox(height: 12.h),
                                _Field(
                                  controller: _titleController,
                                  label: 'عنوان المصروف *',
                                  hint: 'مثال: إيجار شهر يناير',
                                  icon: Icons.title_rounded,
                                  isDark: isDark,
                                  onChanged: () => setState(() {}),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                                ),
                              ]),
                            ),
                            SizedBox(height: 20.h),

                            // التاريخ + ملاحظة.
                            _SectionTitle('التاريخ والملاحظات', isDark: isDark),
                            SizedBox(height: 10.h),
                            InkWell(
                              onTap: () => _pickDate(innerContext),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                                  boxShadow: AppTheme.cardShadow(context),
                                ),
                                child: Row(children: [
                                  Container(width: 42.w, height: 42.w, decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12.r)), child: Icon(Icons.calendar_today_rounded, size: 19.sp, color: const Color(0xFFE11D48))),
                                  SizedBox(width: 12.w),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('التاريخ', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                                    SizedBox(height: 2.h),
                                    Text(DateFormat('EEEE d MMMM yyyy', 'ar').format(_selectedDate), style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                  ])),
                                  Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF94A3B8)),
                                ]),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _Field(
                              controller: _noteController,
                              label: 'ملاحظات (اختياري)',
                              hint: 'ملاحظات إضافية...',
                              icon: Icons.notes_rounded,
                              isDark: isDark,
                              maxLines: 2,
                              onChanged: () {},
                            ),
                            SizedBox(height: 110.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // شريط الحفظ الثابت (مبلغ + حفظ).
            bottomNavigationBar: Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -6))],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المبلغ', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              '${_amount.toStringAsFixed(_amount % 1 == 0 ? 0 : 2)} ج.م',
                              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: const Color(0xFFE11D48), height: 1.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: BlocBuilder<ExpensesCubit, ExpensesState>(
                        builder: (ctx, state) {
                          final loading = state.status == ExpensesStatus.loading;
                          return SizedBox(
                            height: 52.h,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFFB7185)]),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 7))],
                              ),
                              child: FilledButton(
                                onPressed: loading ? null : () => _submit(innerContext),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                ),
                                child: loading
                                    ? SizedBox(width: 22.w, height: 22.w, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded, size: 19.sp, color: Colors.white),
                                          SizedBox(width: 8.w),
                                          Text(_isEditing ? 'حفظ التعديلات' : 'إضافة المصروف', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// عنوان سكشن صغير.
class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionTitle(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
    );
  }
}

/// chip تصنيف بأيقونة ولون.
class _CatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)]) : null,
          color: selected ? null : (isDark ? AppTheme.darkSurfaceAlt : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: selected ? Colors.transparent : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 12, offset: const Offset(0, 5))]
              : AppTheme.cardShadow(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17.sp, color: selected ? Colors.white : color),
            SizedBox(width: 7.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
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

/// حقل المبلغ الكبير.
class _BigAmountField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onChanged;
  final String Function(String) toLatin;

  const _BigAmountField({
    required this.controller,
    required this.isDark,
    required this.onChanged,
    required this.toLatin,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w900, color: const Color(0xFFCBD5E1)),
        suffixText: 'ج.م',
        suffixStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFFE11D48)),
        filled: true,
        fillColor: const Color(0xFFE11D48).withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: const Color(0xFFE11D48).withValues(alpha: 0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.8)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: Color(0xFFE11D48))),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'المبلغ مطلوب';
        final a = double.tryParse(toLatin(v));
        if (a == null || a <= 0) return 'أدخل مبلغ صحيح';
        return null;
      },
      onChanged: (_) => onChanged(),
    );
  }
}

/// حقل عادي موحد.
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  final VoidCallback onChanged;
  final FormFieldValidator<String>? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: (_) => onChanged(),
      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
        labelStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
        prefixIcon: Container(
          margin: EdgeInsets.all(8.w),
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)),
          child: Icon(icon, size: 16.sp, color: const Color(0xFFE11D48)),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: Color(0xFFE11D48))),
      ),
    );
  }
}

/// هيدر الإضافة (رجوع + مبلغ حي).
class _AddHeader extends StatelessWidget {
  final double amount;
  final String category;
  final DateTime date;
  final bool isEditing;
  const _AddHeader({required this.amount, required this.category, required this.date, required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 178.h,
      backgroundColor: const Color(0xFFE11D48),
      foregroundColor: Colors.white,
      elevation: 0,
      stretch: true,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(11.r)),
          child: Icon(Icons.arrow_back_rounded, size: 19.sp, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(isEditing ? 'تعديل المصروف' : 'مصروف جديد', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF5F0A22), Color(0xFFE11D48), Color(0xFFFF7A93)])),
          child: Stack(children: [
            Positioned(top: -50.h, left: -30.w, child: Container(width: 150.w, height: 150.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
            Positioned(bottom: -60.h, right: -40.w, child: Container(width: 170.w, height: 170.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 52.h, 18.w, 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('قيمة المصروف', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                          SizedBox(height: 4.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2),
                                  style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1, letterSpacing: -1),
                                ),
                                SizedBox(width: 7.w),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 5.h),
                                  child: Text('ج.م', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.88))),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.white.withValues(alpha: 0.25))),
                      child: Column(children: [
                        Icon(category.isEmpty ? Icons.category_outlined : expenseCatIcon(category), size: 17.sp, color: Colors.white),
                        SizedBox(height: 3.h),
                        Text(category.isEmpty ? 'التصنيف' : category, style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
