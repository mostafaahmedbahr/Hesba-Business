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

  Future<void> _submit(BuildContext innerContext) async {
    if (!_formKey.currentState!.validate()) return;
    if (_category.isEmpty) { setState(() {}); AppToast.error(innerContext, 'اختر تصنيف المصروف'); return; }
    // تأكد من حل الـ IDs لو لسه فاضية (مثلاً فتح الصفحة بسرعة قبل ما يتحمل shopId)
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
    return BlocProvider(
      create: (_) => ExpensesCubit(expensesRepo: sl())..reset(),
      child: BlocListener<ExpensesCubit, ExpensesState>(
        listener: (ctx, state) {
          if (state.status == ExpensesStatus.success) { HapticFeedback.mediumImpact(); AppToast.success(ctx, _isEditing ? 'تم تعديل المصروف بنجاح' : 'تم إضافة المصروف بنجاح'); Navigator.pop(ctx, true); }
          if (state.status == ExpensesStatus.error) AppToast.error(ctx, state.errorMessage ?? 'حدث خطأ');
        },
        child: Builder(builder: (innerContext) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
              elevation: 0, scrolledUnderElevation: 0,
              centerTitle: true,
              title: Text(_isEditing ? 'تعديل المصروف' : 'إضافة مصروف', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900)),
              leading: IconButton(icon: Icon(Icons.close_rounded, size: 22.sp), onPressed: () => Navigator.pop(context)),
              bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  // معاينة المبلغ
                  _amountPreview(isDark),
                  SizedBox(height: 14.h),
                  _SectionCard(icon: Icons.title_rounded, title: 'بيانات المصروف', gradient: const [Color(0xFFE11D48), Color(0xFFFB7185)], child: Column(children: [
                    _field(controller: _titleController, label: 'العنوان', hint: 'مثال: إيجار شهر يناير', icon: Icons.title_rounded, required: true, validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null),
                    SizedBox(height: 12.h),
                    _field(controller: _amountController, label: 'المبلغ', hint: '0.00', icon: Icons.payments_rounded, suffix: 'ج.م', keyboard: const TextInputType.numberWithOptions(decimal: true), required: true, validator: (v) { if (v == null || v.isEmpty) return 'المبلغ مطلوب'; final a = double.tryParse(_toLatin(v)); if (a == null || a <= 0) return 'أدخل مبلغ صحيح'; return null; }),
                  ])),
                  SizedBox(height: 14.h),
                  _SectionCard(icon: Icons.category_rounded, title: 'التصنيف', gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 8.w, runSpacing: 8.h, children: [
                      for (final cat in AppConstants.expenseCategories)
                        ChoiceChip(
                          label: Text(cat, style: TextStyle(fontSize: 12.sp, fontWeight: _category == cat ? FontWeight.w800 : FontWeight.w600, color: _category == cat ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
                          selected: _category == cat,
                          onSelected: (_) => setState(() => _category = cat),
                          selectedColor: const Color(0xFFE11D48),
                          backgroundColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
                          side: BorderSide(color: _category == cat ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                          showCheckmark: false,
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                          avatar: _category == cat ? Icon(Icons.check_rounded, size: 14.sp, color: Colors.white) : null,
                        ),
                    ]),
                    if (_category.isEmpty) Padding(padding: EdgeInsets.only(top: 8.h), child: Text('اختر تصنيفاً', style: TextStyle(fontSize: 11.sp, color: const Color(0xFFE11D48)))),
                  ])),
                  SizedBox(height: 14.h),
                  _SectionCard(icon: Icons.calendar_today_rounded, title: 'التاريخ والملاحظات', gradient: const [Color(0xFF059669), Color(0xFF34D399)], child: Column(children: [
                    InkWell(
                      onTap: () => _pickDate(innerContext),
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                        decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                        child: Row(children: [
                          Container(width: 36.w, height: 36.w, decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.calendar_today_rounded, size: 16.sp, color: const Color(0xFFE11D48))),
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
                    _field(controller: _noteController, label: 'ملاحظات (اختياري)', hint: 'ملاحظات إضافية...', icon: Icons.notes_rounded, maxLines: 3),
                  ])),
                  SizedBox(height: 22.h),
                  BlocBuilder<ExpensesCubit, ExpensesState>(builder: (ctx, state) {
                    final loading = state.status == ExpensesStatus.loading;
                    return SizedBox(
                      height: 54.h,
                      child: FilledButton(
                        onPressed: loading ? null : () => _submit(innerContext),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))),
                        child: loading
                            ? SizedBox(width: 22.w, height: 22.w, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded, size: 18.sp), SizedBox(width: 8.w), Text(_isEditing ? 'حفظ التعديلات' : 'إضافة المصروف', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800))]),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _amountPreview(bool isDark) {
    final amount = double.tryParse(_toLatin(_amountController.text));
    final hasAmount = amount != null && amount > 0;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF881337), Color(0xFFE11D48), Color(0xFFFB7185)]),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.22))), child: Icon(Icons.savings_rounded, color: Colors.white, size: 26.sp)),
        SizedBox(width: 14.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('قيمة المصروف', style: TextStyle(fontSize: 11.5.sp, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
          SizedBox(height: 4.h),
          Text(hasAmount ? '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)} ج.م' : '-- ج.م', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(height: 2.h),
          Text(_category.isEmpty ? 'اختر التصنيف' : _category, style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.85))),
        ])),
        Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)), child: Text(DateFormat('d MMM', 'ar').format(_selectedDate), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFFBE123C)))),
      ]),
    );
  }

  Widget _SectionCard({required IconData icon, required String title, required List<Color> gradient, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 34.w, height: 34.w, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, color: Colors.white, size: 16.sp)), SizedBox(width: 10.w), Text(title, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)))]),
        SizedBox(height: 14.h),
        child,
      ]),
    );
  }

  Widget _field({required TextEditingController controller, required String label, required IconData icon, String? hint, bool required = false, String? suffix, TextInputType? keyboard, int maxLines = 1, FormFieldValidator<String>? validator}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboard ?? TextInputType.text,
      maxLines: maxLines,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
        labelStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
        prefixIcon: Container(margin: EdgeInsets.all(8.w), width: 36.w, height: 36.w, decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: const Color(0xFFE11D48))),
        suffixText: suffix,
        suffixStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFFE11D48)),
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
