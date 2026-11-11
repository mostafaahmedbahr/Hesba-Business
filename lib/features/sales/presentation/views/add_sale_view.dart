import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../accounts/data/models/person_model.dart';
import '../../../accounts/data/repos/accounts_repo.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/sale_model.dart';
import '../cubit/sales_cubit.dart';
import '../cubit/sales_state.dart';
import '../widgets/add_sale_button.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/sale_customer_section.dart';
import '../widgets/sale_product_card.dart';
import '../widgets/sale_summary.dart';
import '../../../subscription/presentation/subscription_gate.dart';

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

  // العميل (اختياري) — اسم ورقم يُكتبان معًا أو يُتركان فاضيين.
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();

  String _paymentMethod = AppConstants.paymentCash;

  List<Product> _availableProducts = [];
  StreamSubscription<List<Product>>? _productsSub;
  bool _loadingProducts = true;

  List<PersonModel> _persons = [];
  StreamSubscription<List<PersonModel>>? _personsSub;

  // Resolved ids (owner/shop of the current account, via ShopResolver)
  String? _resolvedOwnerId;
  String? _resolvedShopId;

  @override
  void initState() {
    super.initState();
    _resolvedOwnerId = widget.ownerId;
    _resolvedShopId = widget.shopId;
    _resolveIds();
    _loadProducts();
    _loadPersons();
    _addItem();
    _discountController.addListener(_onRecalc);
  }

  Future<void> _resolveIds() async {
    final resolver = sl<ShopResolver>();
    if (_resolvedOwnerId == null || _resolvedOwnerId!.isEmpty) {
      _resolvedOwnerId = resolver.currentUid;
    }
    if (_resolvedShopId == null || _resolvedShopId!.isEmpty) {
      _resolvedShopId = await resolver.getShopId();
    }
    if (mounted) setState(() {});
  }

  void _loadProducts() {
    try {
      final repo = sl<ProductsRepo>();
      _productsSub = repo.watchProducts().listen(
        (products) {
          if (!mounted) return;
          // نحتفظ بكل المنتجات (نشط + غير نشط) عشان غير النشط يظهر في البحث
          // بعلامة "غير متاح" ومش قابل للاختيار بدل ما يختفي خالص.
          setState(() {
            _availableProducts = products;
            _loadingProducts = false;
            // منتج اتشال من النشاط واكننا مختارينه، نمسحه قبل الحفظ.
            for (final e in _items) {
              if (e.selectedProduct == null) continue;
              final current = _findProduct(e.selectedProduct!.id);
              if (current != null && !current.isActive) {
                e.selectedProduct = null;
                e.price.clear();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) AppToast.warning(context, 'saleInactiveProduct'.tr(namedArgs: {'name': current.name}));
                });
              } else if (current != null) {
                e.selectedProduct = current;
              }
            }
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

  /// جهات الاتصال المحفوظة — تُستخدم في اقتراحات العميل أثناء الكتابة.
  void _loadPersons() {
    try {
      _personsSub = sl<AccountsRepo>().watchPersons().listen(
        (persons) {
          if (!mounted) return;
          setState(() => _persons = persons);
        },
        onError: (_) {},
      );
    } catch (_) {}
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
        quantity: NumberParser.parseDouble(e.quantity.text),
        unitPrice: NumberParser.parseDouble(e.price.text),
        costPrice: e.selectedProduct?.costPrice ?? 0,
      );
    }).toList();
  }

  Product? _findProduct(String id) {
    for (final p in _availableProducts) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool _isInactiveTypedName(String name) {
    final q = name.trim().toLowerCase();
    if (q.isEmpty) return false;
    return _availableProducts.any((p) => !p.isActive && p.name.trim().toLowerCase() == q);
  }

  double get _subtotal {
    return _items.fold(0, (acc, e) {
      final q = NumberParser.parseDouble(e.quantity.text);
      final p = NumberParser.parseDouble(e.price.text);
      return acc + (q * p);
    });
  }

  double get _discount {
    return NumberParser.parseDouble(_discountController.text);
  }

  double get _total {
    final d = _discount;
    final capped = d > _subtotal ? _subtotal : d;
    final res = _subtotal - (capped < 0 ? 0 : capped);
    return res < 0 ? 0 : res;
  }

  Future<void> _submit(BuildContext innerContext) async {
    if (!await SubscriptionGate.ensureCanModify(innerContext)) return;
    if (!innerContext.mounted) return;
    // منتج غير نشط مبيتفعلش في حاجة: مش بيتختار ومش بيتباع.
    for (int i = 0; i < _items.length; i++) {
      final e = _items[i];
      if (e.selectedProduct != null && !e.selectedProduct!.isActive) {
        AppToast.warning(innerContext, 'saleInactiveProduct'.tr(namedArgs: {'name': e.selectedProduct!.name}));
        return;
      }
      if (e.selectedProduct == null && _isInactiveTypedName(e.name.text.trim())) {
        AppToast.warning(innerContext, 'saleInactiveProduct'.tr(namedArgs: {'name': e.name.text.trim()}));
        return;
      }
    }
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(innerContext, 'saleReviewData'.tr());
      return;
    }

    // العميل اختياري — لكن اسمه ورقمه يُكتبان معًا.
    // (البيع الآجل حالة خاصة: العميل إجباري لأن الذمة بتتربط به.)
    final customerName = _customerNameController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();
    if (customerName.isEmpty != customerPhone.isEmpty) {
      AppToast.warning(innerContext, 'saleCustomerBothRequired'.tr());
      return;
    }
    if (_paymentMethod == AppConstants.paymentCredit &&
        (customerName.isEmpty || customerPhone.isEmpty)) {
      AppToast.warning(innerContext, 'saleCreditRequiresCustomer'.tr());
      return;
    }
    if (customerPhone.isNotEmpty) {
      final phoneError = Validators.egyptianPhone(customerPhone);
      if (phoneError != null) {
        AppToast.warning(innerContext, 'contactPhoneInvalid'.tr());
        return;
      }
    }

    // Extra validation for each row required fields
    for (int i = 0; i < _items.length; i++) {
      final e = _items[i];
      if (e.name.text.trim().isEmpty) {
        AppToast.warning(innerContext, 'saleNameRequiredRow'.tr(namedArgs: {'i': '${i + 1}'}));
        return;
      }
      final q = NumberParser.parseDouble(e.quantity.text.trim());
      final p = NumberParser.parseDouble(e.price.text.trim());
      if (q <= 0) {
        AppToast.warning(innerContext, 'saleQtyInvalidRow'.tr(namedArgs: {'i': '${i + 1}'}));
        return;
      }
      if (p <= 0) {
        AppToast.warning(innerContext, 'salePriceInvalidRow'.tr(namedArgs: {'i': '${i + 1}'}));
        return;
      }
      if (e.selectedProduct != null && q > e.selectedProduct!.stock) {
        AppToast.warning(innerContext, 'saleQtyExceeds'.tr(namedArgs: {'stock': '${e.selectedProduct!.stock}', 'name': e.name.text}));
        return;
      }
    }

    if (_resolvedShopId == null || _resolvedShopId!.isEmpty) {
      AppToast.error(innerContext, 'noShopData'.tr());
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
          customerName: customerName.isEmpty ? null : customerName,
          customerPhone: customerPhone.isEmpty ? null : customerPhone,
        );
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _personsSub?.cancel();
    for (final e in _items) {
      e.dispose();
    }
    _discountController.removeListener(_onRecalc);
    _discountController.dispose();
    _noteController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
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
                final isCredit = _paymentMethod == AppConstants.paymentCredit;
                AppToast.success(
                  ctx,
                  (isCredit ? 'saleSavedCredit' : 'saleSaved').tr(),
                );
                Navigator.pop(ctx, true);
              }
              if (state.status == SalesStatus.error) {
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
                                  Text('saleItemsTitle'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
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
                                    Text('saleAvailableStock'.tr(namedArgs: {'n': '${_availableProducts.where((p) => p.isActive).length}'}), style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text('saleSearchHint'.tr(), style: TextStyle(fontSize: 11.5.sp, color: AppTheme.mutedGray)),
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
                                        AppToast.warning(innerContext, 'saleMinOneRow'.tr());
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
                                      Text('saleAddAnother'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h),

                              // الدفع.
                              Text('salePaymentMethod'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
                              SizedBox(height: 10.h),
                              PaymentMethodSelector(
                                value: _paymentMethod,
                                onChanged: (v) => setState(() => _paymentMethod = v),
                              ),
                              SizedBox(height: 20.h),

                              // العميل (اختياري) لربط الفاتورة بجهة اتصال.
                              SaleCustomerSection(
                                nameController: _customerNameController,
                                phoneController: _customerPhoneController,
                                persons: _persons,
                                creditRequired:
                                    _paymentMethod == AppConstants.paymentCredit,
                              ),
                              SizedBox(height: 20.h),

                              // الخصم + ملاحظة.
                              Text('saleExtras'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
                              SizedBox(height: 10.h),
                              Container(
                                padding: EdgeInsets.all(14.w),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(18.r),
                                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
                                  boxShadow: AppTheme.cardShadow(context),
                                ),
                                child: Column(children: [
                                  TextFormField(
                                    controller: _discountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      labelText: 'saleDiscountLabel'.tr(),
                                      hintText: '0',
                                      suffixText: 'currencyEGP'.tr(),
                                      prefixIcon: Container(
                                        margin: EdgeInsets.all(8.w),
                                        width: 34.w,
                                        height: 34.w,
                                        decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)),
                                        child: Icon(Icons.discount_rounded, size: 17.sp, color: AppTheme.danger),
                                      ),
                                      filled: true,
                                      fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6)),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return null;
                                      final d = double.tryParse(v);
                                      if (d == null) return 'saleDiscountInvalid'.tr();
                                      if (d < 0) return 'saleDiscountNegative'.tr();
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
                                      labelText: 'saleNoteLabel'.tr(),
                                      hintText: 'saleNoteHint'.tr(),
                                      hintStyle: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray),
                                      prefixIcon: Container(
                                        margin: EdgeInsets.all(8.w),
                                        width: 34.w,
                                        height: 34.w,
                                        decoration: BoxDecoration(color: AppTheme.slateGray.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)),
                                        child: Icon(Icons.note_alt_outlined, size: 17.sp, color: AppTheme.slateGray),
                                      ),
                                      filled: true,
                                      fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft)),
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
                            Text('saleTotalLabel'.tr(), style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray, fontWeight: FontWeight.w600)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                'saleTotalAmount'.tr(namedArgs: {'total': _total.toStringAsFixed(_total == _total.roundToDouble() ? 0 : 2), 'currency': 'currencyEGP'.tr()}),
                                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: AppTheme.successDark, height: 1.1),
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
      title: Text('saleNewTitle'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF0A1F5C), AppTheme.primaryColor, Color(0xFF6D9BFF)])),
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
                          Text('saleInvoiceTotal'.tr(), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
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
                                  child: Text('currencyEGP'.tr(), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.88))),
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
                        Text('saleItemsUnit'.tr(), style: TextStyle(fontSize: 10.sp, color: Colors.white.withValues(alpha: 0.85))),
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
