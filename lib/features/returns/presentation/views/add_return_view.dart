import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';
import '../../../../core/services/shop_resolver.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/utils/number_parser.dart';
import '../../../../core/utils/toast.dart';
import '../../../products/data/repos/products_repo.dart';
import '../../data/repos/returns_repo.dart';
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
  StreamSubscription<List<SaleModel>>? _salesSub;
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
    final resolver = sl<ShopResolver>();
    if (_resolvedOwnerId == null || _resolvedOwnerId!.isEmpty) {
      _resolvedOwnerId = resolver.currentUid;
    }
    if (_resolvedShopId == null || _resolvedShopId!.isEmpty) {
      _resolvedShopId = await resolver.getShopId();
    }
    // business type
    try {
      final repo = sl<ProductsRepo>();
      _shopBusinessType = await repo.getShopBusinessType();
      _shopBusinessType ??= await resolver.getShopBusinessType();
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
      _salesSub = sl<ReturnsRepo>()
          .watchShopSales(shopId: _resolvedShopId!)
          .listen((sales) {
        if (!mounted) return;
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
      final map = await sl<ReturnsRepo>().getAlreadyReturnedQuantities(saleId);
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
      final qty = NumberParser.parseDouble(e.qtyController.text);
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
      final qty = NumberParser.parseDouble(e.qtyController.text);
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
    if (!innerContext.mounted) return;
    if (!(_formKey.currentState?.validate() ?? true)) {
      AppToast.warning(innerContext, 'retReviewData'.tr());
      return;
    }
    if (_selectedSale == null) {
      AppToast.warning(innerContext, 'retChooseInvoice'.tr());
      return;
    }
    if (_historyFailed) {
      AppToast.error(innerContext, 'retHistoryFailed'.tr());
      return;
    }
    final items = _buildReturnItems();
    if (items.isEmpty) {
      AppToast.warning(innerContext, 'retMinOne'.tr());
      return;
    }
    if (_reason == null || _reason!.trim().isEmpty) {
      AppToast.warning(innerContext, 'retChooseReason'.tr());
      return;
    }
    // Validate qty not exceed max
    for (final e in _entries.values) {
      if (!e.selected) continue;
      final qty = NumberParser.parseDouble(e.qtyController.text);
      if (qty > e.maxQty + 0.001) {
        AppToast.warning(innerContext, 'retQtyExceeds'.tr(namedArgs: {'name': e.saleItem.productName, 'max': '${e.maxQty}'}));
        return;
      }
    }
    if (_resolvedShopId == null || _resolvedShopId!.isEmpty) {
      AppToast.error(innerContext, 'noShopData'.tr());
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
    for (final e in _entries.values) {
      e.qtyController.dispose();
    }
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
                AppToast.success(ctx, 'retSaved'.tr());
                Navigator.pop(ctx, true);
              }
              if (state.status == ReturnsStatus.error) {
                AppToast.error(ctx, translateError(state.errorMessage, state.errorArgs));
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
                              _SectionTitle('retInvoiceSection'.tr()),
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
                                  _SectionTitle('retItemsSection'.tr()),
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                                    decoration: BoxDecoration(color: AppTheme.warningAmber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20.r)),
                                    child: Text('retSelectedCount'.tr(namedArgs: {'n': '$_selectedCount'}), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppTheme.amberDark)),
                                  ),
                                ]),
                                SizedBox(height: 4.h),
                                Text('retOriginalPriceNote'.tr(), style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray)),
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
                                _SectionTitle('retReasonSection'.tr()),
                                if (_shopBusinessType != null) ...[
                                  SizedBox(height: 4.h),
                                  Text('retBusinessLine'.tr(namedArgs: {'type': '$_shopBusinessType'}), style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray)),
                                ],
                                SizedBox(height: 10.h),
                                ReturnReasonChips(
                                  reasons: _availableReasons,
                                  selected: _reason,
                                  onSelected: (v) => setState(() => _reason = v),
                                ),
                                SizedBox(height: 18.h),
                                _SectionTitle('retNoteSection'.tr()),
                                SizedBox(height: 8.h),
                                Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
                                  ),
                                  child: TextFormField(
                                    controller: _noteController,
                                    maxLines: 2,
                                    style: TextStyle(fontSize: 13.sp),
                                    decoration: InputDecoration(
                                      hintText: 'retNoteHint'.tr(),
                                      hintStyle: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray),
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
                        border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.hairline)),
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
                                  Text('retRefundLabel'.tr(), style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray, fontWeight: FontWeight.w600)),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      'retNetAmount'.tr(namedArgs: {'total': _netReturn.toStringAsFixed(_netReturn == _netReturn.roundToDouble() ? 0 : 2), 'currency': 'currencyEGP'.tr()}),
                                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: AppTheme.amberDark, height: 1.1),
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
                                        gradient: const LinearGradient(colors: [AppTheme.warningAmber, AppTheme.goldLight]),
                                        borderRadius: BorderRadius.circular(16.r),
                                        boxShadow: [BoxShadow(color: AppTheme.warningAmber.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 7))],
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
                                                  Text('retSave'.tr(), style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w900, color: Colors.white)),
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
      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink),
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
      backgroundColor: AppTheme.warningAmber,
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
      title: Text('retNewTitle'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF92400E), AppTheme.warningAmber, AppTheme.goldLight])),
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
                          Text('retRefundAmount'.tr(), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.88))),
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
                                  child: Text('currencyEGP'.tr(), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.90))),
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
                        Text('retSelectedUnit'.tr(), style: TextStyle(fontSize: 10.sp, color: Colors.white.withValues(alpha: 0.88))),
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
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.16)),
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
              Text('retInvoiceLine'.tr(namedArgs: {'id': idShort, 'count': '${sale.items.length}', 'unit': sale.items.length == 1 ? 'retUnitOne'.tr() : 'retUnitMany'.tr()}), style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.ink)),
              Text('retInvoiceTotals'.tr(namedArgs: {'total': sale.total.toStringAsFixed(2), 'currency': 'currencyEGP'.tr(), 'discount': sale.discount.toStringAsFixed(0)}), style: TextStyle(fontSize: 11.sp, color: AppTheme.slateGray)),
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
