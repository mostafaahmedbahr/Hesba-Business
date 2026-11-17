import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/shop_resolver.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_parser.dart';
import '../../../../core/utils/toast.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';
import '../../data/models/expense_model.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import '../widgets/add_expense/add_header.dart';
import '../widgets/add_expense/category_section.dart';
import '../widgets/add_expense/date_picker_row.dart';
import '../widgets/add_expense/details_card.dart';
import '../widgets/add_expense/field.dart';
import '../widgets/add_expense/recurrence_hint.dart';
import '../widgets/add_expense/recurrence_section.dart';
import '../widgets/add_expense/save_bar.dart';
import '../widgets/add_expense/section_title.dart';
import '../widgets/add_expense/time_picker_row.dart';

/// شاشة إضافة/تعديل مصروف (هيدر حي + شريط حفظ ثابت).
class AddExpenseView extends StatefulWidget {
  final String? ownerId;
  final String? shopName;
  final String? shopId;
  final ExpenseModel? expense;

  /// حساب الموظف يضيف مصروفًا فقط ولا يفتح شاشة قائمة المصروفات.
  final bool restricted;

  const AddExpenseView({
    super.key,
    this.ownerId,
    this.shopName,
    this.shopId,
    this.expense,
    this.restricted = false,
  });

  @override
  State<AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<AddExpenseView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _shopNameController = TextEditingController();
  String _category = '';
  DateTime _selectedDate = DateTime.now();
  String? _resolvedOwnerId;
  String? _resolvedShopId;
  String? _resolvedShopName;
  bool _isEditing = false;

  // التكرار: مرة واحدة ('') أو يومي/أسبوعي/شهري — مع موعد استحقاق.
  String _recurrence = ExpenseModel.recurrenceNone;
  TimeOfDay _dueTime = const TimeOfDay(hour: 9, minute: 0);

  bool get isRecurring => _recurrence != ExpenseModel.recurrenceNone;

  String get _recurrenceHint {
    const prefix = 'هتتسجّل تلقائيًا ';
    switch (_recurrence) {
      case ExpenseModel.recurrenceDaily:
        return '${prefix}يوميًا — وإشعار قبل الميعاد بساعتين';
      case ExpenseModel.recurrenceWeekly:
        return '${prefix}أسبوعيًا — وإشعار قبل الميعاد بيوم';
      case ExpenseModel.recurrenceMonthly:
        return '${prefix}شهريًا — وإشعار قبل الميعاد بيومين';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _resolvedOwnerId = widget.ownerId;
    _resolvedShopId = widget.shopId;
    _resolvedShopName = widget.shopName ?? widget.expense?.shopName;
    _isEditing = widget.expense != null;
    if (_isEditing && widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toStringAsFixed(
        widget.expense!.amount % 1 == 0 ? 0 : 2,
      );
      _noteController.text = widget.expense!.note;
      _shopNameController.text = widget.expense!.shopName;
      _category = widget.expense!.category;
      _selectedDate = widget.expense!.date;
      _recurrence = widget.expense!.recurrence;
      final t = _parseDueTimeString(widget.expense!.dueTime);
      if (t != null) _dueTime = t;
      _resolvedShopName ??= widget.expense!.shopName;
    }
    _resolveIds();
  }

  Future<void> _resolveIds() async {
    final resolver = sl<ShopResolver>();
    if (_resolvedOwnerId == null || _resolvedOwnerId!.isEmpty) {
      _resolvedOwnerId = resolver.currentUid;
    }
    if (_resolvedShopId == null || _resolvedShopId!.isEmpty) {
      _resolvedShopId = await resolver.getShopId();
    }
    if (_resolvedShopName == null || _resolvedShopName!.isEmpty) {
      _resolvedShopName = await resolver.getShopName();
    }
    if ((_shopNameController.text.trim().isEmpty) && (_resolvedShopName != null && _resolvedShopName!.isNotEmpty)) {
      _shopNameController.text = _resolvedShopName!;
    }
    if (mounted) setState(() {});
  }

  /// المبلغ الحالي (بعد تحويل الأرقام العربية).
  double get _amount => NumberParser.parseDouble(_amountController.text.trim());

  Future<void> _submit(BuildContext innerContext) async {
    if (!await SubscriptionGate.ensureCanModify(innerContext)) return;
    if (!innerContext.mounted) return;
    if (!_formKey.currentState!.validate()) return;
    if (_category.isEmpty) {
      AppToast.error(innerContext, 'اختر تصنيف المصروف');
      return;
    }
    // تأكد من حل الـ IDs لو لسه فاضية.
    if (_resolvedShopId == null ||
        _resolvedShopId!.isEmpty ||
        _resolvedOwnerId == null ||
        _resolvedOwnerId!.isEmpty) {
      await _resolveIds();
    }
    if (!innerContext.mounted) return;
    final title = _titleController.text.trim();
    final amount = NumberParser.parseDouble(_amountController.text.trim());
    final note = _noteController.text.trim();
    final shopName = _shopNameController.text.trim().isNotEmpty
        ? _shopNameController.text.trim()
        : (_resolvedShopName ?? '');
    HapticFeedback.lightImpact();
    if (_isEditing && widget.expense != null) {
      await innerContext.read<ExpensesCubit>().updateExpense(
        expenseId: widget.expense!.expenseId,
        shopName: shopName,
        ownerId: _resolvedOwnerId ?? '',
        shopId: _resolvedShopId ?? '',
        title: title,
        category: _category,
        amount: amount,
        note: note,
        date: _selectedDate,
        recurrence: _recurrence,
        dueTime: _dueTimeString,
      );
    } else {
      await innerContext.read<ExpensesCubit>().addExpense(
        ownerId: _resolvedOwnerId ?? '',
        shopId: _resolvedShopId ?? '',
        shopName: shopName,
        title: title,
        category: _category,
        amount: amount,
        note: note,
        date: _selectedDate,
        recurrence: _recurrence,
        dueTime: _dueTimeString,
      );
    }
  }

  /// صيغة 'HH:mm' لما يحتاجها المستودع والجدولة.
  String get _dueTimeString =>
      '${_dueTime.hour.toString().padLeft(2, '0')}:${_dueTime.minute.toString().padLeft(2, '0')}';

  static TimeOfDay? _parseDueTimeString(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// اختيار الوقت (يُستخدم فقط عندما يكون المصروف مكررًا).
  Future<void> _pickTime(BuildContext innerContext) async {
    final picked = await showTimePicker(
      context: innerContext,
      initialTime: _dueTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.amberDeep),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  String _toLatin(String input) => input
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9')
      .replaceAll('۰', '0')
      .replaceAll('۱', '1')
      .replaceAll('۲', '2')
      .replaceAll('۳', '3')
      .replaceAll('۴', '4')
      .replaceAll('۵', '5')
      .replaceAll('۶', '6')
      .replaceAll('۷', '7')
      .replaceAll('۸', '8')
      .replaceAll('۹', '9');

  Future<void> _pickDate(BuildContext innerContext) async {
    final picked = await showDatePicker(
      context: innerContext,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.danger),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _shopNameController.dispose();
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
            AppToast.success(
              ctx,
              _isEditing ? 'تم تعديل المصروف بنجاح' : 'تم إضافة المصروف بنجاح',
            );
            Navigator.pop(ctx, true);
          }
          if (state.status == ExpensesStatus.error)
            AppToast.error(ctx, state.errorMessage ?? 'حدث خطأ');
        },
        child: Builder(
          builder: (innerContext) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SafeArea(
                top: false,
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    slivers: [
                      // هيدر gradient بالمبلغ الحي.
                      ExpenseAddHeader(
                        amount: _amount,
                        category: _category,
                        date: _selectedDate,
                        isEditing: _isEditing,
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ExpenseSectionTitle('التصنيف', isDark: isDark),
                              SizedBox(height: 10.h),
                              ExpenseCategorySection(
                                category: _category,
                                isDark: isDark,
                                onSelect: (cat) =>
                                    setState(() => _category = cat),
                              ),
                              SizedBox(height: 20.h),

                              // المبلغ + العنوان.
                              ExpenseSectionTitle('التفاصيل', isDark: isDark),
                              SizedBox(height: 10.h),
                              ExpenseDetailsCard(
                                amountController: _amountController,
                                titleController: _titleController,
                                shopNameController: _shopNameController,
                                isDark: isDark,
                                onChanged: () => setState(() {}),
                                toLatin: _toLatin,
                              ),
                              SizedBox(height: 20.h),

                              // التكرار (مرة واحدة / يومي / أسبوعي / شهري).
                              ExpenseSectionTitle('التكرار', isDark: isDark),
                              SizedBox(height: 10.h),
                              ExpenseRecurrenceSection(
                                recurrence: _recurrence,
                                isDark: isDark,
                                onSelect: (value) =>
                                    setState(() => _recurrence = value),
                              ),
                              if (isRecurring) ...[
                                SizedBox(height: 14.h),
                                ExpenseTimePickerRow(
                                  dueTime: _dueTime,
                                  isDark: isDark,
                                  onTap: () => _pickTime(innerContext),
                                ),
                                SizedBox(height: 10.h),
                                ExpenseRecurrenceHint(hint: _recurrenceHint),
                              ],
                              SizedBox(height: 20.h),

                              // التاريخ + ملاحظة.
                              ExpenseSectionTitle(
                                'التاريخ والملاحظات',
                                isDark: isDark,
                              ),
                              SizedBox(height: 10.h),
                              ExpenseDatePickerRow(
                                selectedDate: _selectedDate,
                                isDark: isDark,
                                onTap: () => _pickDate(innerContext),
                              ),
                              SizedBox(height: 12.h),
                              ExpenseField(
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
              bottomNavigationBar: ExpenseSaveBar(
                isDark: isDark,
                amount: _amount,
                isEditing: _isEditing,
                onSubmit: () => _submit(innerContext),
              ),
            );
          },
        ),
      ),
    );
  }
}
