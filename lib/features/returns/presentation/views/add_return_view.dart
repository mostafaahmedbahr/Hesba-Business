import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';
import '../../../../core/utils/toast.dart';
import '../../../products/data/repos/products_repo.dart';
import '../../../sales/data/models/sale_model.dart';
import '../../data/models/return_model.dart';
import '../cubit/returns_cubit.dart';
import '../cubit/returns_state.dart';

class AddReturnView extends StatefulWidget {
  final String? ownerId;
  final String? shopId;
  final String? originalSaleId;

  const AddReturnView({
    super.key,
    this.ownerId,
    this.shopId,
    this.originalSaleId,
  });

  @override
  State<AddReturnView> createState() => _AddReturnViewState();
}

class _AddReturnViewState extends State<AddReturnView> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  // Sale selection
  List<SaleModel> _sales = [];
  SaleModel? _selectedSale;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _salesSub;
  bool _loadingSales = true;

  // Products for category lookup
  List<Product> _availableProducts = [];
  StreamSubscription<List<Product>>? _productsSub;
  String? _shopBusinessType;

  // Return items derived from sale
  final Map<String, _ReturnEntry> _entries = {}; // key = productId+index

  // Already returned qty per productId
  final Map<String, double> _alreadyReturned = {};

  String? _reason;
  List<String> _availableReasons = AppConstants.genericReturnReasons;

  String? _resolvedOwnerId;
  String? _resolvedShopId;

  @override
  void initState() {
    super.initState();
    _resolvedOwnerId = widget.ownerId;
    _resolvedShopId = widget.shopId;
    _resolveIdsAndBusinessType();
    _loadSales();
    _loadProducts();
  }

  Future<void> _resolveIdsAndBusinessType() async {
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
    // business type
    try {
      final repo = sl<ProductsRepo>();
      _shopBusinessType = await repo.getShopBusinessType();
      if (_shopBusinessType == null && _resolvedShopId != null) {
        final shopDoc = await FirebaseFirestore.instance.collection('shops').doc(_resolvedShopId).get();
        _shopBusinessType = shopDoc.data()?['businessType'] as String?;
      }
    } catch (_) {}
    _updateReasons();
    if (mounted) setState(() {});
    // If originalSaleId provided, auto-select after sales loaded
    if (widget.originalSaleId != null) {
      // will be handled after _sales loaded
    }
  }

  void _loadProducts() {
    try {
      final repo = sl<ProductsRepo>();
      _productsSub = repo.watchProducts().listen((products) {
        if (!mounted) return;
        setState(() => _availableProducts = products.where((p) => p.isActive).toList());
        _updateReasons();
      });
    } catch (_) {}
  }

  void _loadSales() {
    () async {
      // Ensure shopId resolved first
      for (int i = 0; i < 10 && (_resolvedShopId == null || _resolvedShopId!.isEmpty); i++) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (_resolvedShopId == null || _resolvedShopId!.isEmpty) {
        if (mounted) setState(() => _loadingSales = false);
        return;
      }
      _salesSub = FirebaseFirestore.instance
          .collection(AppConstants.salesCollection)
          .where('shopId', isEqualTo: _resolvedShopId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        final sales = snap.docs.map((d) => SaleModel.fromJson(d.data())).toList();
        setState(() {
          _sales = sales;
          _loadingSales = false;
          // Auto-select if originalSaleId provided
          if (widget.originalSaleId != null && _selectedSale == null) {
            try {
              final found = sales.firstWhere((s) => s.saleId == widget.originalSaleId);
              _selectSale(found);
            } catch (_) {}
          }
        });
      }, onError: (_) {
        if (mounted) setState(() => _loadingSales = false);
      });
    }();
  }

  Future<void> _selectSale(SaleModel sale) async {
    setState(() {
      _selectedSale = sale;
      _entries.clear();
      _alreadyReturned.clear();
      _reason = null;
    });
    await _loadAlreadyReturned(sale.saleId);
    // Initialize entries for each item in sale
    for (int i = 0; i < sale.items.length; i++) {
      final item = sale.items[i];
      final key = '${item.productId}::$i';
      final already = _alreadyReturned[key] ?? _alreadyReturned[item.productId] ?? 0;
      final maxQty = (item.quantity - already).clamp(0, item.quantity);
      _entries[key] = _ReturnEntry(
        saleItem: item,
        key: key,
        maxQty: maxQty.toDouble(),
        alreadyReturned: already.toDouble(),
        selected: false,
        qtyController: TextEditingController(text: maxQty > 0 ? maxQty.toStringAsFixed(maxQty % 1 == 0 ? 0 : 1) : '0'),
      );
    }
    _updateReasons();
    setState(() {});
  }

  Future<void> _loadAlreadyReturned(String saleId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.returnsCollection)
          .where('originalSaleId', isEqualTo: saleId)
          .get();
      final map = <String, double>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final items = (data['items'] as List<dynamic>? ?? []);
        for (int i = 0; i < items.length; i++) {
          final it = Map<String, dynamic>.from(items[i]);
          final pid = it['productId'] as String? ?? '';
          final qty = (it['quantity'] as num?)?.toDouble() ?? 0;
          final saleItems = _selectedSale?.items ?? [];
          // Try to match by productId if exists
          if (pid.isNotEmpty) {
            map[pid] = (map[pid] ?? 0) + qty;
          } else {
            // fallback by index if no productId (legacy sale items without id)
            final key = '::$i';
            map[key] = (map[key] ?? 0) + qty;
          }
          // Also by productName fallback
          final pname = it['productName'] as String? ?? '';
          if (pname.isNotEmpty) {
            map['name::$pname'] = (map['name::$pname'] ?? 0) + qty;
          }
        }
      }
      _alreadyReturned.clear();
      _alreadyReturned.addAll(map);
    } catch (_) {}
  }

  void _updateReasons() {
    if (_selectedSale == null) {
      _availableReasons = AppConstants.getReturnReasons(businessType: _shopBusinessType);
    } else {
      final categories = <String>{};
      for (final item in _selectedSale!.items) {
        Product? prod;
        if (item.productId.isNotEmpty) {
          try {
            prod = _availableProducts.firstWhere((p) => p.id == item.productId);
          } catch (_) {}
        }
        if (prod != null && prod.category.isNotEmpty) categories.add(prod.category);
      }
      if (categories.isEmpty) {
        _availableReasons = AppConstants.getReturnReasons(businessType: _shopBusinessType);
      } else if (categories.length == 1) {
        _availableReasons = AppConstants.getReturnReasons(businessType: _shopBusinessType, category: categories.first);
      } else {
        // Merge reasons for all categories
        final merged = <String>{};
        for (final cat in categories) {
          merged.addAll(AppConstants.getReturnReasons(businessType: _shopBusinessType, category: cat));
        }
        _availableReasons = merged.toList();
      }
    }
    // Keep selected reason valid
    if (_reason != null && !_availableReasons.contains(_reason)) {
      _reason = null;
    }
    _reason ??= _availableReasons.isNotEmpty ? _availableReasons.first : null;
  }

  double get _grossReturn {
    double sum = 0;
    for (final e in _entries.values) {
      if (!e.selected) continue;
      final qty = double.tryParse(e.qtyController.text) ?? 0;
      sum += qty * e.saleItem.unitPrice;
    }
    return sum;
  }

  double get _discountRatio {
    if (_selectedSale == null) return 0;
    final sub = _selectedSale!.subtotal;
    if (sub <= 0) return 0;
    return (_selectedSale!.discount / sub).clamp(0.0, 1.0).toDouble();
  }

  double get _allocatedDiscount => double.parse((_grossReturn * _discountRatio).toStringAsFixed(2));

  double get _netReturn => double.parse((_grossReturn - _allocatedDiscount).clamp(0, _grossReturn).toStringAsFixed(2));

  double get _totalReturn => _netReturn; // alias for backward compat

  List<ReturnItemModel> _buildReturnItems() {
    final list = <ReturnItemModel>[];
    for (final e in _entries.values) {
      if (!e.selected) continue;
      final qty = double.tryParse(e.qtyController.text) ?? 0;
      if (qty <= 0) continue;
      list.add(ReturnItemModel(
        productId: e.saleItem.productId,
        productName: e.saleItem.productName,
        quantity: qty,
        unitPrice: e.saleItem.unitPrice,
      ));
    }
    return list;
  }

  void _submit(BuildContext innerContext) {
    if (_selectedSale == null) {
      AppToast.warning(innerContext, 'اختر فاتورة أولاً');
      return;
    }
    final items = _buildReturnItems();
    if (items.isEmpty) {
      AppToast.warning(innerContext, 'حدد منتج واحد على الأقل للإرجاع');
      return;
    }
    if (_reason == null || _reason!.trim().isEmpty) {
      AppToast.warning(innerContext, 'اختر سبب المرتجع');
      return;
    }
    // Validate qty not exceed max
    for (final e in _entries.values) {
      if (!e.selected) continue;
      final qty = double.tryParse(e.qtyController.text) ?? 0;
      if (qty > e.maxQty + 0.001) {
        AppToast.warning(innerContext, 'الكمية للإرجاع أكبر من المتاح لـ ${e.saleItem.productName} (المتاح: ${e.maxQty})');
        return;
      }
    }
    if (_resolvedShopId == null || _resolvedShopId!.isEmpty) {
      AppToast.error(innerContext, 'لم يتم العثور على بيانات المتجر');
      return;
    }
    innerContext.read<ReturnsCubit>().addReturn(
          ownerId: _resolvedOwnerId ?? '',
          shopId: _resolvedShopId!,
          originalSaleId: _selectedSale!.saleId,
          items: items,
          reason: _reason!,
          note: _noteController.text,
        );
  }

  @override
  void dispose() {
    _salesSub?.cancel();
    _productsSub?.cancel();
    for (final e in _entries.values) e.qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReturnsCubit(returnsRepo: sl())..reset(),
      child: Builder(
        builder: (innerContext) {
          return BlocListener<ReturnsCubit, ReturnsState>(
            listener: (ctx, state) {
              if (state.status == ReturnsStatus.success) {
                AppToast.success(ctx, 'تم حفظ المرتجع وزيادة المخزون بنجاح');
                Navigator.pop(ctx, true);
              }
              if (state.status == ReturnsStatus.error) {
                AppToast.error(ctx, state.errorMessage ?? 'حدث خطأ');
              }
            },
            child: Scaffold(
              appBar: AppBar(title: const Text('إضافة مرتجع'), centerTitle: true),
              body: SafeArea(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sale picker
                        Text('اختر الفاتورة', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                        SizedBox(height: 8.h),
                        if (_loadingSales)
                          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                        else if (_sales.isEmpty)
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
                            child: Row(children: [
                              Icon(Icons.receipt_long_rounded, color: Colors.orange.shade700),
                              SizedBox(width: 10.w),
                              Expanded(child: Text('لا توجد فواتير — المرتجع يجب أن يكون من عملية بيع سابقة', style: TextStyle(fontSize: 12.sp))),
                            ]),
                          )
                        else
                          Autocomplete<SaleModel>(
                            displayStringForOption: (s) => 'فاتورة #${s.saleId.substring(0, 6)} - ${DateFormat('dd/MM').format(s.createdAt)} - ${s.total.toStringAsFixed(0)} ج.م',
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) return _sales.take(8);
                              final q = textEditingValue.text.toLowerCase();
                              return _sales.where((s) =>
                                  s.saleId.toLowerCase().contains(q) ||
                                  s.items.any((it) => it.productName.toLowerCase().contains(q)));
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: 280.h, maxWidth: 360.w),
                                    child: ListView.separated(
                                      padding: EdgeInsets.all(6.w),
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      separatorBuilder: (_, __) => Divider(height: 1.h),
                                      itemBuilder: (context, index) {
                                        final s = options.elementAt(index);
                                        final date = DateFormat('dd/MM/yyyy hh:mm a', 'ar').format(s.createdAt);
                                        return ListTile(
                                          dense: true,
                                          title: Text('فاتورة #${s.saleId.substring(0, 6)} - ${s.total.toStringAsFixed(0)} ج.م', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                                          subtitle: Text('$date • ${s.items.length} صنف • خصم ${s.discount.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp)),
                                          trailing: s.saleId == _selectedSale?.saleId ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                                          onTap: () => onSelected(s),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                              // Show selected sale in field
                              if (_selectedSale != null && textController.text.isEmpty) {
                                textController.text = 'فاتورة #${_selectedSale!.saleId.substring(0, 6)}';
                              }
                              return TextFormField(
                                controller: textController,
                                focusNode: focusNode,
                                readOnly: false,
                                decoration: InputDecoration(
                                  hintText: 'ابحث برقم الفاتورة أو اسم المنتج',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _selectedSale != null
                                      ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () {
                                          textController.clear();
                                          setState(() {
                                            _selectedSale = null;
                                            _entries.clear();
                                            _reason = null;
                                          });
                                        })
                                      : null,
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (v) => _selectedSale == null ? 'اختر فاتورة' : null,
                              );
                            },
                            onSelected: (sale) => _selectSale(sale),
                          ),

                        if (_selectedSale != null) ...[
                          SizedBox(height: 16.h),
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.receipt_long_rounded, size: 16.sp, color: Theme.of(context).colorScheme.primary),
                                  SizedBox(width: 6.w),
                                  Text('تفاصيل الفاتورة', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  Text(DateFormat('dd/MM/yyyy').format(_selectedSale!.createdAt), style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                                ]),
                                SizedBox(height: 6.h),
                                Text('الإجمالي: ${_selectedSale!.total.toStringAsFixed(2)} ج.م  •  الخصم: ${_selectedSale!.discount.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700)),
                                if (_selectedSale!.note.isNotEmpty) Text('ملاحظة: ${_selectedSale!.note}', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text('حدد الأصناف للإرجاع', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                          SizedBox(height: 8.h),
                          Text('المرتجع يحسب بنفس سعر البيع الأصلي (الخصم محفوظ في الفاتورة)', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                          SizedBox(height: 12.h),
                          ..._entries.values.map((e) {
                            final item = e.saleItem;
                            final isOutOfReturnable = e.maxQty <= 0;
                            return Container(
                              margin: EdgeInsets.only(bottom: 10.h),
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: isOutOfReturnable ? Colors.grey.shade100 : Colors.white,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(color: e.selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300, width: e.selected ? 1.6 : 1),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: e.selected && !isOutOfReturnable,
                                        onChanged: isOutOfReturnable ? null : (v) => setState(() => e.selected = v ?? false),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.productName, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                                            Text('سعر: ${item.unitPrice.toStringAsFixed(2)} ج.م • الكمية المباعة: ${item.quantity} • المرتجع سابقاً: ${e.alreadyReturned} • المتاح: ${e.maxQty}',
                                                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                                            if (isOutOfReturnable)
                                              Text('تم إرجاع كل الكمية بالفعل', style: TextStyle(fontSize: 11.sp, color: Colors.red.shade600, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (e.selected && !isOutOfReturnable) ...[
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: e.qtyController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                              labelText: 'كمية الإرجاع',
                                              suffixText: '/ ${e.maxQty}',
                                              border: const OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                            ),
                                            validator: (v) {
                                              if (!e.selected) return null;
                                              final q = double.tryParse(v ?? '');
                                              if (q == null || q <= 0) return 'مطلوب';
                                              if (q > e.maxQty) return 'الحد ${e.maxQty}';
                                              return null;
                                            },
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('${( (double.tryParse(e.qtyController.text) ?? 0) * item.unitPrice * (1 - _discountRatio)).toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                                            if (_discountRatio > 0)
                                              Text('قبل الخصم ${( (double.tryParse(e.qtyController.text) ?? 0) * item.unitPrice).toStringAsFixed(2)}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                          SizedBox(height: 16.h),
                          Text('سبب المرتجع (حسب قسم المنتج)', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                          SizedBox(height: 8.h),
                          if (_shopBusinessType != null)
                            Text('نشاط المحل: $_shopBusinessType', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                          SizedBox(height: 8.h),
                          DropdownButtonFormField<String>(
                            value: _reason,
                            decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.assignment_return_rounded), labelText: 'السبب'),
                            items: _availableReasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(fontSize: 13.sp)))).toList(),
                            onChanged: (v) => setState(() => _reason = v),
                            validator: (v) => (v == null || v.isEmpty) ? 'اختر السبب' : null,
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _noteController,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', hintText: 'مثال: عيب مصنعي واضح...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note_alt_outlined)),
                          ),
                          SizedBox(height: 20.h),
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.orange.withValues(alpha: 0.2))),
                            child: Column(
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('قبل الخصم', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700)),
                                  Text('${_grossReturn.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, decoration: _discountRatio > 0 ? TextDecoration.lineThrough : null)),
                                ]),
                                if (_discountRatio > 0) ...[
                                  SizedBox(height: 6.h),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text('حصة الخصم (${(_discountRatio * 100).toStringAsFixed(0)}%)', style: TextStyle(fontSize: 12.sp, color: Colors.red.shade600)),
                                    Text('-${_allocatedDiscount.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.red.shade600)),
                                  ]),
                                ],
                                Divider(height: 16.h),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('المبلغ المسترد (يدخل حسابك)', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
                                  Text('${_netReturn.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.orange.shade700)),
                                ]),
                              ],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text('المرتجع يُحسب بنسبة خصم الفاتورة الأصلية (${(_discountRatio * 100).toStringAsFixed(1)}%) — يُخصم فقط المبلغ المدفوع فعلاً', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                          SizedBox(height: 20.h),
                          BlocBuilder<ReturnsCubit, ReturnsState>(
                            builder: (ctx, state) {
                              final loading = state.status == ReturnsStatus.loading;
                              return SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: loading ? null : () => _submit(innerContext),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))),
                                  child: loading
                                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('حفظ المرتجع', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReturnEntry {
  final SaleItemModel saleItem;
  final String key;
  final double maxQty;
  final double alreadyReturned;
  bool selected;
  final TextEditingController qtyController;

  _ReturnEntry({
    required this.saleItem,
    required this.key,
    required this.maxQty,
    required this.alreadyReturned,
    required this.selected,
    required this.qtyController,
  });
}
