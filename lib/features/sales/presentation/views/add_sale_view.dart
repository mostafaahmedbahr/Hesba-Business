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
import '../../../../core/widgets/loading_widget.dart';
import '../../../products/data/repos/products_repo.dart';
import '../../../accounts/data/models/person_model.dart';
import '../../../accounts/data/repos/accounts_repo.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/sale_model.dart';
import '../cubit/sales_cubit.dart';
import '../cubit/sales_state.dart';
import '../widgets/invoice_sheet.dart';
import '../widgets/add_sale_button.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/sale_customer_section.dart';
import '../widgets/sale_product_card.dart';
import '../widgets/sale_summary.dart';
import '../widgets/add_sale/add_sale_header.dart';
import '../widgets/add_sale/add_sale_bottom_bar.dart';
import '../widgets/add_sale/sale_items_section.dart';
import '../widgets/add_sale/sale_extras_section.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import 'package:hesba/core/services/app_logger.dart';

/// شاشة بيع جديد (فورم + ملخص live + شريط حفظ ثابت).
class AddSaleView extends StatefulWidget {
  final String? ownerId;
  final String? shopId;

  /// عند true (حساب الموظف): لا يُعرض قسم العميل ولا خيار البيع الآجل،
  /// حتى لا يستطيع الموظف الوصول لبيانات العملاء أو إنشاء ذمم.
  final bool restricted;

  const AddSaleView({
    super.key,
    this.ownerId,
    this.shopId,
    this.restricted = false,
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
    if (!widget.restricted) _loadPersons();
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
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/sales/presentation/views/add_sale_view.dart', logErr, logSt, severity: LoggingSeverity.warning);
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
    } catch (logErr, logSt) { AppLogger.nonFatal('features/sales/presentation/views/add_sale_view.dart', logErr, logSt, severity: LoggingSeverity.warning); }
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
    // الحساب الفرعي لا يرى العملاء ولا يمكنه البيع الآجل (منع الذمم).
    String? customerName;
    String? customerPhone;
    if (!widget.restricted) {
      customerName = _customerNameController.text.trim();
      customerPhone = _customerPhoneController.text.trim();
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
          customerName: (customerName == null || customerName.isEmpty) ? null : customerName,
          customerPhone: (customerPhone == null || customerPhone.isEmpty) ? null : customerPhone,
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
            listener: (ctx, state) async {
              if (state.status == SalesStatus.error) {
                AppToast.error(ctx, translateError(state.errorMessage, state.errorArgs));
              }
              if (state.status == SalesStatus.success) {
                final isCredit = _paymentMethod == AppConstants.paymentCredit;
                AppToast.success(
                  ctx,
                  (isCredit ? 'saleSavedCredit' : 'saleSaved').tr(),
                );
                // خيار إصدار فاتورة (صورة) وإرسالها للعميل بعد الحفظ.
                final sale = state.sale;
                if (sale != null && ctx.mounted) {
                  final issue = await askIssueInvoice(ctx);
                  if (issue && ctx.mounted) {
                    await showInvoiceSheet(ctx, sale);
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
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
                      AddSaleHeader(
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
                                    const LoadingWidget(size: 16, compact: true)
                                  else
                                    Text('saleAvailableStock'.tr(namedArgs: {'n': '${_availableProducts.where((p) => p.isActive).length}'}), style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text('saleSearchHint'.tr(), style: TextStyle(fontSize: 11.5.sp, color: AppTheme.mutedGray)),
                              SizedBox(height: 12.h),

                              SaleItemsSection(
                                isDark: isDark,
                                itemsCount: _items.length,
                                loadingProducts: _loadingProducts,
                                availableActiveCount: _availableProducts.where((p) => p.isActive).length,
                                items: _items,
                                availableProducts: _availableProducts,
                                onAddItem: _addItem,
                                onRemoveItem: (index) {
                                  if (_items.length == 1) {
                                    AppToast.warning(innerContext, 'saleMinOneRow'.tr());
                                    return;
                                  }
                                  _removeItem(index);
                                },
                                onProductSelected: (index, p) {
                                  setState(() => _items[index].selectedProduct = p);
                                },
                                onChanged: _onRecalc,
                              ),
                              SizedBox(height: 20.h),

                              // الدفع.
                              Text('salePaymentMethod'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
                              SizedBox(height: 10.h),
                              PaymentMethodSelector(
                                value: _paymentMethod,
                                allowCredit: !widget.restricted,
                                onChanged: (v) => setState(() => _paymentMethod = v),
                              ),
                              SizedBox(height: 20.h),

                              // العميل (اختياري) لربط الفاتورة بجهة اتصال.
                              // مخفي تمامًا في حساب الموظف.
                              if (!widget.restricted) ...[
                                SaleCustomerSection(
                                  nameController: _customerNameController,
                                  phoneController: _customerPhoneController,
                                  persons: _persons,
                                  creditRequired:
                                      _paymentMethod == AppConstants.paymentCredit,
                                ),
                                SizedBox(height: 20.h),
                              ],

                              SaleExtrasSection(
                                isDark: isDark,
                                discountController: _discountController,
                                noteController: _noteController,
                                subtotal: _subtotal,
                                discount: _discount,
                                total: _total,
                                itemsCount: _items.length,
                                onRecalc: _onRecalc,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // شريط الحفظ الثابت (إجمالي + حفظ).
              bottomNavigationBar: BlocBuilder<SalesCubit, SalesState>(
                builder: (ctx, state) {
                  final loading = state.status == SalesStatus.loading;
                  return AddSaleBottomBar(
                    total: _total,
                    loading: loading,
                    onSave: loading ? () {} : () => _submit(innerContext),
                  );
                },
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
