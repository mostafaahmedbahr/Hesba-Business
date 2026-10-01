import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../../products/data/repos/products_repo.dart';
import '../../data/models/sale_model.dart';
import '../cubit/sales_cubit.dart';
import '../cubit/sales_state.dart';
import '../widgets/add_sale_button.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/sale_product_card.dart';
import '../widgets/sale_summary.dart';

/// شاشة بيع جديد (فورم + ملخص live + شريط حفظ ثابت).
class AddSaleView extends StatefulWidget {
  final String? ownerId;
  final String? shopId;

  const AddSaleView({
    super.key,
    this.ownerId,
    this.shopId,
  });

  @override
  State<AddSaleView> createState() => _AddSaleViewState();
}

class _AddSaleViewState extends State<AddSaleView> {
  final _formKey = GlobalKey<FormState>();
  final List<_SaleItemControllers> _items = [];

  final _discountController = TextEditingController();
  final _noteController = TextEditingController();

  String _paymentMethod = AppConstants.paymentCash;

  List<Product> _availableProducts = [];
  StreamSubscription<List<Product>>? _productsSub;
  bool _loadingProducts = true;

  // Resolved ids (fallback to FirebaseAuth + Firestore lookup)
  String? _resolvedOwnerId;
  String? _resolvedShopId;

  @override
  void initState() {
    super.initState();
    _resolvedOwnerId = widget.ownerId;
    _resolvedShopId = widget.shopId;
    _resolveIds();
    _loadProducts();
    _addItem();
    _discountController.addListener(_onRecalc);
  }

  Future<void> _resolveIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_resolvedOwnerId == null || _resolvedOwnerId!.isEmpty) {
      _resolvedOwnerId = uid;
    }
    if (_resolvedShopId == null || _resolvedShopId!.isEmpty) {
      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          _resolvedShopId = doc.data()?['shopId'] as String?;
        } catch (_) {}
      }
    }
    if (mounted) setState(() {});
  }

  void _loadProducts() {
    try {
      final repo = sl<ProductsRepo>();
      _productsSub = repo.watchProducts().listen(
        (products) {
          if (!mounted) return;
          setState(() {
            _availableProducts = products.where((p) => p.isActive).toList();
            _loadingProducts = false;
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _loadingProducts = false);
        },
      );
      // Fallback timeout if stream doesn't emit
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _loadingProducts) {
          setState(() => _loadingProducts = false);
        }
      });
    } catch (_) {
      _loadingProducts = false;
    }
  }

  void _onRecalc() => setState(() {});

  void _addItem() {
    final c = _SaleItemControllers();
    c.quantity.addListener(_onRecalc);
    c.price.addListener(_onRecalc);
    c.name.addListener(_onRecalc);
    setState(() => _items.add(c));
    HapticFeedback.lightImpact();
  }

  void _removeItem(int index) {
    final removed = _items.removeAt(index);
    removed.dispose();
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  List<SaleItemModel> _buildItems() {
    return _items.map((e) {
      return SaleItemModel(
        productId: e.selectedProduct?.id ?? '',
        productName: e.name.text.trim(),
        quantity: double.tryParse(e.quantity.text.trim()) ?? 0,
        unitPrice: double.tryParse(e.price.text.trim()) ?? 0,
      );
    }).toList();
  }

  double get _subtotal {
    return _items.fold(0, (sum, e) {
      final q = double.tryParse(e.quantity.text) ?? 0;
      final p = double.tryParse(e.price.text) ?? 0;
      return sum + (q * p);
    });
  }

  double get _discount {
    return double.tryParse(_discountController.text) ?? 0;
  }

  double get _total {
    final d = _discount;
    final capped = d > _subtotal ? _subtotal : d;
    final res = _subtotal - (capped < 0 ? 0 : capped);
    return res < 0 ? 0 : res;
  }

  void _submit(BuildContext innerContext) {
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(innerContext, 'راجع بيانات المنتجات');
      return;
    }

    // Extra validation for each row required fields
    for (int i = 0; i < _items.length; i++) {
      final e = _items[i];
      if (e.name.text.trim().isEmpty) {
        AppToast.warning(innerContext, 'اسم المنتج مطلوب في السطر ${i + 1}');
        return;
      }
      final q = double.tryParse(e.quantity.text.trim());
      final p = double.tryParse(e.price.text.trim());
      if (q == null || q <= 0) {
        AppToast.warning(innerContext, 'الكمية غير صحيحة في السطر ${i + 1}');
        return;
      }
      if (p == null || p <= 0) {
        AppToast.warning(innerContext, 'السعر غير صحيح في السطر ${i + 1}');
        return;
      }
      if (e.selectedProduct != null && q > e.selectedProduct!.stock) {
        AppToast.warning(innerContext, 'الكمية أكبر من المتاح (${e.selectedProduct!.stock}) في ${e.name.text}');
        return;
      }
    }

    if (_resolvedShopId == null || _resolvedShopId!.isEmpty) {
      AppToast.error(innerContext, 'لم يتم العثور على بيانات المتجر');
      return;
    }

    final items = _buildItems();
    innerContext.read<SalesCubit>().addSale(
          ownerId: _resolvedOwnerId ?? '',
          shopId: _resolvedShopId!,
          items: items,
          discount: _discount,
          paymentMethod: _paymentMethod,
          note: _noteController.text,
        );
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    for (final e in _items) {
      e.dispose();
    }
    _discountController.removeListener(_onRecalc);
    _discountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => SalesCubit(salesRepo: sl())..reset(),
      // Use Builder to obtain innerContext that has access to SalesCubit
      child: Builder(
        builder: (innerContext) {
          return BlocListener<SalesCubit, SalesState>(
            listener: (ctx, state) {
              if (state.status == SalesStatus.success) {
                AppToast.success(ctx, 'تم حفظ عملية البيع بنجاح');
                Navigator.pop(ctx, true);
              }
              if (state.status == SalesStatus.error) {
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
                      // هيدر gradient بالإجمالي الحي.
                      _AddHeader(
                        total: _total,
                        itemsCount: _items.length,
                        subtotal: _subtotal,
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // عنوان الأصناف + المتاح.
                              Row(
                                children: [
                                  Text('الأصناف', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                                    decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20.r)),
                                    child: Text('${_items.length}', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                                  ),
                                  const Spacer(),
                                  if (_loadingProducts)
                                    SizedBox(width: 16.w, height: 16.w, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                                  else
                                    Text('${_availableProducts.length} متاح بالمخزون', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text('ابحث واختار من المخزون أو اكتب صنف يدوياً', style: TextStyle(fontSize: 11.5.sp, color: const Color(0xFF94A3B8))),
                              SizedBox(height: 12.h),

                              // كروت الأصناف.
                              ...List.generate(_items.length, (index) {
                                final e = _items[index];
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12.h),
                                  child: SaleProductCard(
                                    index: index,
                                    nameController: e.name,
                                    quantityController: e.quantity,
                                    priceController: e.price,
                                    availableProducts: _availableProducts,
                                    selectedProduct: e.selectedProduct,
                                    onProductSelected: (p) {
                                      setState(() => e.selectedProduct = p);
                                    },
                                    onChanged: _onRecalc,
                                    onDelete: () {
                                      if (_items.length == 1) {
                                        AppToast.warning(innerContext, 'يجب أن يبقى صنف واحد على الأقل');
                                        return;
                                      }
                                      _removeItem(index);
                                    },
                                  ),
                                );
                              }),

                              // زرار إضافة صنف (dashed).
                              InkWell(
                                onTap: _addItem,
                                borderRadius: BorderRadius.circular(16.r),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.35), width: 1.4, style: BorderStyle.solid),
                                    color: AppTheme.primaryColor.withValues(alpha: 0.04),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_circle_outline_rounded, size: 19.sp, color: AppTheme.primaryColor),
                                      SizedBox(width: 8.w),
                                      Text('إضافة صنف آخر', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h),

                              // الدفع.
                              Text('طريقة الدفع', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              SizedBox(height: 10.h),
                              PaymentMethodSelector(
                                value: _paymentMethod,
                                onChanged: (v) => setState(() => _paymentMethod = v),
                              ),
                              SizedBox(height: 20.h),

                              // الخصم + ملاحظة.
                              Text('إضافات', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
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
                                  TextFormField(
                                    controller: _discountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      labelText: 'الخصم',
                                      hintText: '0',
                                      suffixText: 'ج.م',
                                      prefixIcon: Container(
                                        margin: EdgeInsets.all(8.w),
                                        width: 34.w,
                                        height: 34.w,
                                        decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)),
                                        child: Icon(Icons.discount_rounded, size: 17.sp, color: const Color(0xFFE11D48)),
                                      ),
                                      filled: true,
                                      fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6)),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return null;
                                      final d = double.tryParse(v);
                                      if (d == null) return 'رقم غير صحيح';
                                      if (d < 0) return 'لا يمكن أن يكون سالباً';
                                      return null;
                                    },
                                    onChanged: (_) => _onRecalc(),
                                  ),
                                  SizedBox(height: 12.h),
                                  TextFormField(
                                    controller: _noteController,
                                    maxLines: 2,
                                    style: TextStyle(fontSize: 13.sp),
                                    decoration: InputDecoration(
                                      labelText: 'ملاحظة (اختياري)',
                                      hintText: 'مثال: بيع لعميل دائم...',
                                      hintStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                                      prefixIcon: Container(
                                        margin: EdgeInsets.all(8.w),
                                        width: 34.w,
                                        height: 34.w,
                                        decoration: BoxDecoration(color: const Color(0xFF64748B).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)),
                                        child: Icon(Icons.note_alt_outlined, size: 17.sp, color: const Color(0xFF64748B)),
                                      ),
                                      filled: true,
                                      fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6)),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                                    ),
                                  ),
                                ]),
                              ),
                              SizedBox(height: 16.h),

                              // الملخص.
                              SaleSummary(
                                subtotal: _subtotal,
                                discount: _discount > _subtotal
                                    ? _subtotal
                                    : (_discount < 0 ? 0 : _discount),
                                total: _total,
                                itemsCount: _items.length,
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
              // شريط الحفظ الثابت (إجمالي + حفظ).
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
                            Text('الإجمالي', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                '${_total.toStringAsFixed(_total == _total.roundToDouble() ? 0 : 2)} ج.م',
                                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: const Color(0xFF059669), height: 1.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: BlocBuilder<SalesCubit, SalesState>(
                          builder: (ctx, state) {
                            final loading = state.status == SalesStatus.loading;
                            return AddSaleButton(
                              loading: loading,
                              onPressed: loading ? () {} : () => _submit(innerContext),
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

/// هيدر الإضافة (رجوع + عنوان + إجمالي حي).
class _AddHeader extends StatelessWidget {
  final double total;
  final int itemsCount;
  final double subtotal;
  const _AddHeader({required this.total, required this.itemsCount, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 178.h,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      stretch: true,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(11.r)),
          child: Icon(Icons.arrow_back_rounded, size: 19.sp, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('بيع جديد', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF0A1F5C), Color(0xFF1A4FD6), Color(0xFF6D9BFF)])),
          child: Stack(children: [
            Positioned(top: -50.h, left: -30.w, child: Container(width: 150.w, height: 150.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
            Positioned(bottom: -60.h, right: -40.w, child: Container(width: 170.w, height: 170.w, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF5A623).withValues(alpha: 0.13)))),
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
                          Text('إجمالي الفاتورة', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                          SizedBox(height: 4.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  total.toStringAsFixed(total == total.roundToDouble() ? 0 : 2),
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
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                      child: Column(children: [
                        Text('$itemsCount', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                        Text('أصناف', style: TextStyle(fontSize: 10.sp, color: Colors.white.withValues(alpha: 0.85))),
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

class _SaleItemControllers {
  final name = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController();
  Product? selectedProduct;

  void dispose() {
    name.dispose();
    quantity.dispose();
    price.dispose();
  }
}
