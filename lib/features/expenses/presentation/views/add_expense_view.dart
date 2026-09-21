import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/toast.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';
import '../widgets/add_expense_button.dart';
import '../widgets/expense_category_selector.dart';
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
      _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      _noteController.text = widget.expense!.note;
      _category = widget.expense!.category;
      _selectedDate = widget.expense!.date;
    }
    _resolveIds();
  }

  Future<void> _resolveIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_resolvedOwnerId == null || _resolvedOwnerId!.isEmpty) {
      _resolvedOwnerId = uid;
    }
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

  void _submit(BuildContext innerContext) {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final note = _noteController.text.trim();
    final category = _category;
    final date = _selectedDate;

    if (_isEditing && widget.expense != null) {
      innerContext.read<ExpensesCubit>().updateExpense(
        expenseId: widget.expense!.expenseId,
        ownerId: _resolvedOwnerId ?? '',
        shopId: _resolvedShopId ?? '',
        title: title,
        category: category,
        amount: amount,
        note: note,
        date: date,
      );
    } else {
      innerContext.read<ExpensesCubit>().addExpense(
        ownerId: _resolvedOwnerId ?? '',
        shopId: _resolvedShopId ?? '',
        title: title,
        category: category,
        amount: amount,
        note: note,
        date: date,
      );
    }
  }

  Future<void> _pickDate(BuildContext innerContext) async {
    final picked = await showDatePicker(
      context: innerContext,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpensesCubit(expensesRepo: sl())..reset(),
      child: BlocListener<ExpensesCubit, ExpensesState>(
        listener: (ctx, state) {
          if (state.status == ExpensesStatus.success) {
            AppToast.success(ctx, _isEditing ? 'تم تعديل المصروف بنجاح' : 'تم إضافة المصروف بنجاح');
            Navigator.pop(ctx, true);
          }
          if (state.status == ExpensesStatus.error) {
            AppToast.error(ctx, state.errorMessage ?? 'حدث خطأ');
          }
        },
        child: Builder(
          builder: (innerContext) {
            return Scaffold(
              appBar: AppBar(
                title: Text(_isEditing ? 'تعديل المصروف' : 'إضافة مصروف'),
              ),
              body: SafeArea(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان',
                            hintText: 'مثال: إيجار شهر يناير',
                            prefixIcon: Icon(Icons.title_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'العنوان مطلوب';
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'المبلغ',
                            hintText: '0.00',
                            suffixText: 'ج.م',
                            prefixIcon: const Icon(Icons.payments_rounded),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'المبلغ مطلوب';
                            final amount = double.tryParse(v);
                            if (amount == null || amount <= 0) return 'أدخل مبلغ صحيح';
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        ExpenseCategorySelector(
                          value: _category,
                          onChanged: (v) => setState(() => _category = v),
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات (اختياري)',
                            hintText: 'ملاحظات إضافية...',
                            prefixIcon: Icon(Icons.note_alt_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        GestureDetector(
                          onTap: () => _pickDate(innerContext),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'التاريخ',
                              prefixIcon: Icon(Icons.calendar_today_rounded),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        BlocBuilder<ExpensesCubit, ExpensesState>(
                          builder: (ctx, state) {
                            final loading = state.status == ExpensesStatus.loading;
                            return AddExpenseButton(
                              loading: loading,
                              onPressed: loading ? () {} : () => _submit(innerContext),
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
