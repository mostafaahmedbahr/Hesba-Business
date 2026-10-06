import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../../products/data/repos/products_repo.dart';
import '../../../sales/data/models/sale_model.dart';
import '../../data/models/return_model.dart';
import '../cubit/returns_cubit.dart';
import '../cubit/returns_state.dart';
import '../widgets/return_invoice_picker.dart';
import '../widgets/return_item_card.dart';
import '../widgets/return_reason_chips.dart';
import '../widgets/return_summary.dart';
import '../../../subscription/presentation/subscription_gate.dart';

/// شاشة إضافة مرتجع (اختيار فاتورة + أصناف + ملخص حي + شريط حفظ ثابت).
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

  // True when the previous-returns lookup failed: maxQty is then
  // overestimated, so submitting must be blocked until it succeeds.
  bool _historyFailed = false;

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

  void _clearSale() {
    setState(() {
      _selectedSale = null;
      _entries.clear();
      _reason = null;
    });
  }

  Future<void> _loadAlreadyReturned(String saleId) async {
    _historyFailed = false;
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
          if (pid.isNotEmpty) {
            map[pid] = (map[pid] ?? 0) + qty;
          } else {
            final key = '::$i';
            map[key] = (map[key] ?? 0) + qty;
          }
          final pname = it['productName'] as String? ?? '';
          if (pname.isNotEmpty) {
            map['name::$pname'] = (map['name::$pname'] ?? 0) + qty;
          }
        }
      }
      _alreadyReturned.clear();
      _alreadyReturned.addAll(map);
    } catch (_) {
      // Fail closed: without history the editable max is unreliable.
      _historyFailed = true;
    }
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

  /// عدد الأصناف المحددة.
  int get _selectedCount => _entries.values.where((e) => e.selected).length;

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

  Future<void> _submit(BuildContext innerContext) async {
    if (!await SubscriptionGate.ensureCanModify(innerContext)) return;
    if (!(_formKey.currentState?.validate() ?? true)) {
      AppToast.warning(innerContext, 'راجع بيانات المرتجع');
      return;
    }
    if (_selectedSale == null) {
      AppToast.warning(innerContext, 'اختر فاتورة أولاً');
      return;
    }
    if (_historyFailed) {
      AppToast.error(innerContext, 'تعذر التحقق من المرتجعات السابقة — تحقق من الاتصال وأعد اختيار الفاتورة');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SafeArea(
                top: false,
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    slivers: [
                      // هيدر gradient بالمسترد الحي.
                      _ReturnHeader(net: _netReturn, count: _selectedCount),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle('الفاتورة'),
                              SizedBox(height: 8.h),
                              ReturnInvoicePicker(
                                sales: _sales,
                                loading: _loadingSales,
                                selected: _selectedSale,
                                onSelected: _selectSale,
                                onClear: _clearSale,
                              ),

                              if (_selectedSale != null) ...[
                                SizedBox(height: 12.h),
                                _SaleStrip(sale: _selectedSale!),
                                SizedBox(height: 18.h),
                                Row(children: [
                                  _SectionTitle('الأصناف للإرجاع'),
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20.r)),
                                    child: Text('$_selectedCount محدد', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFFB45309))),
                                  ),
                                ]),
                                SizedBox(height: 4.h),
                                Text('بنفس سعر البيع الأصلي — الخصم محفوظ في الفاتورة', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
                                SizedBox(height: 10.h),
                                ..._entries.values.map((e) => Padding(
                                      padding: EdgeInsets.only(bottom: 10.h),
                                      child: ReturnItemCard(
                                        item: e.saleItem,
                                        selected: e.selected,
                                        returnable: e.maxQty > 0,
                                        maxQty: e.maxQty,
                                        alreadyReturned: e.alreadyReturned,
                                        discountRatio: _discountRatio,
                                        qtyController: e.qtyController,
                                        onSelect: (v) => setState(() => e.selected = v),
                                        onQtyChanged: () => setState(() {}),
                                      ),
                                    )),
                                SizedBox(height: 18.h),
                                _SectionTitle('سبب المرتجع'),
                                if (_shopBusinessType != null) ...[
                                  SizedBox(height: 4.h),
                                  Text('حسب نشاط: $_shopBusinessType', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
                                ],
                                SizedBox(height: 10.h),
                                ReturnReasonChips(
                                  reasons: _availableReasons,
                                  selected: _reason,
                                  onSelected: (v) => setState(() => _reason = v),
                                ),
                                SizedBox(height: 18.h),
                                _SectionTitle('ملاحظة'),
                                SizedBox(height: 8.h),
                                Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                                  ),
                                  child: TextFormField(
                                    controller: _noteController,
                                    maxLines: 2,
                                    style: TextStyle(fontSize: 13.sp),
                                    decoration: InputDecoration(
                                      hintText: 'مثال: عيب مصنعي واضح...',
                                      hintStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                ReturnSummary(
                                  gross: _grossReturn,
                                  discountRatio: _discountRatio,
                                  allocatedDiscount: _allocatedDiscount,
                                  net: _netReturn,
                                ),
                              ],
                              SizedBox(height: 110.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // شريط الحفظ الثابت (مسترد + حفظ).
              bottomNavigationBar: _selectedSale == null
                  ? null
                  : Container(
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
                                  Text('المسترد', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      '${_netReturn.toStringAsFixed(_netReturn == _netReturn.roundToDouble() ? 0 : 2)} ج.م',
                                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: const Color(0xFFB45309), height: 1.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              flex: 2,
                              child: BlocBuilder<ReturnsCubit, ReturnsState>(
                                builder: (ctx, state) {
                                  final loading = state.status == ReturnsStatus.loading;
                                  return SizedBox(
                                    height: 52.h,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
                                        borderRadius: BorderRadius.circular(16.r),
                                        boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 7))],
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
                                                  Icon(Icons.check_circle_rounded, size: 20.sp, color: Colors.white),
                                                  SizedBox(width: 8.w),
                                                  Text('حفظ المرتجع', style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w900, color: Colors.white)),
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
            ),
          );
        },
      ),
    );
  }
}

/// عنوان سكشن صغير.
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
    );
  }
}

/// هيدر الإضافة (رجوع + مسترد حي).
class _ReturnHeader extends StatelessWidget {
  final double net;
  final int count;
  const _ReturnHeader({required this.net, required this.count});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 178.h,
      backgroundColor: const Color(0xFFF59E0B),
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
      title: Text('مرتجع جديد', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF92400E), Color(0xFFF59E0B), Color(0xFFFBBF24)])),
          child: Stack(children: [
            Positioned(top: -50.h, left: -30.w, child: Container(width: 150.w, height: 150.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.10)))),
            Positioned(bottom: -60.h, right: -40.w, child: Container(width: 170.w, height: 170.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
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
                          Text('المبلغ المسترد', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.88))),
                          SizedBox(height: 4.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  net.toStringAsFixed(net == net.roundToDouble() ? 0 : 2),
                                  style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1, letterSpacing: -1),
                                ),
                                SizedBox(width: 7.w),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 5.h),
                                  child: Text('ج.م', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.90))),
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
                        Text('$count', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                        Text('محدد', style: TextStyle(fontSize: 10.sp, color: Colors.white.withValues(alpha: 0.88))),
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

/// شريط الفاتورة المختارة.
class _SaleStrip extends StatelessWidget {
  final SaleModel sale;
  const _SaleStrip({required this.sale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idShort = sale.saleId.length >= 6 ? sale.saleId.substring(0, 6) : sale.saleId;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A4FD6).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF1A4FD6).withValues(alpha: 0.16)),
      ),
      child: Row(children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10.r)),
          child: Icon(Icons.receipt_long_rounded, size: 17.sp, color: Colors.white),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('فاتورة #$idShort • ${sale.items.length} ${sale.items.length == 1 ? 'صنف' : 'أصناف'}', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              Text('إجماليها ${sale.total.toStringAsFixed(2)} ج.م • خصم ${sale.discount.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ]),
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
