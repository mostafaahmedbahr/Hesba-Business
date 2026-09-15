import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';
import '../../../../core/utils/toast.dart';
import '../../../products/data/repos/products_repo.dart';
import '../../data/models/sale_model.dart';
import '../cubit/sales_cubit.dart';
import '../cubit/sales_state.dart';
import '../widgets/add_sale_button.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/sale_product_card.dart';
import '../widgets/sale_summary.dart';

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
  }

  void _removeItem(int index) {
    final removed = _items.removeAt(index);
    removed.dispose();
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
              appBar: AppBar(
                title: const Text('إضافة بيع جديد'),
                centerTitle: true,
              ),
              body: SafeArea(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('المنتجات',
                                style: TextStyle(
                                    fontSize: 18.sp, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (_loadingProducts)
                              SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(strokeWidth: 2))
                            else
                              Text('${_availableProducts.length} منتج متاح',
                                  style: TextStyle(
                                      fontSize: 11.sp, color: Colors.grey.shade600)),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text('ابحث واختر من المخزون أو اكتب منتج يدوياً',
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
                        SizedBox(height: 12.h),

                        ...List.generate(_items.length, (index) {
                          final e = _items[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: SaleProductCard(
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
                                  AppToast.warning(innerContext, 'يجب أن يبقى منتج واحد على الأقل');
                                  return;
                                }
                                _removeItem(index);
                              },
                            ),
                          );
                        }),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('إضافة منتج آخر'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r)),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),
                        Text('الخصم وطريقة الدفع',
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.w700)),
                        SizedBox(height: 12.h),

                        TextFormField(
                          controller: _discountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'الخصم',
                            hintText: '0',
                            suffixText: 'ج.م',
                            prefixIcon: const Icon(Icons.discount_rounded),
                            border: const OutlineInputBorder(),
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

                        SizedBox(height: 16.h),

                        PaymentMethodSelector(
                          value: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v),
                        ),

                        SizedBox(height: 16.h),

                        TextFormField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات (اختياري)',
                            hintText: 'مثال: بيع لعميل دائم...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note_alt_outlined),
                          ),
                        ),

                        SizedBox(height: 20.h),

                        SaleSummary(
                          subtotal: _subtotal,
                          discount: _discount > _subtotal
                              ? _subtotal
                              : (_discount < 0 ? 0 : _discount),
                          total: _total,
                          itemsCount: _items.length,
                        ),

                        SizedBox(height: 20.h),

                        BlocBuilder<SalesCubit, SalesState>(
                          builder: (ctx, state) {
                            final loading = state.status == SalesStatus.loading;
                            return AddSaleButton(
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
            ),
          );
        },
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
