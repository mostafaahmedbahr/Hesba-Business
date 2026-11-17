import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';
import '../../../../core/services/shop_resolver.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_parser.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import '../../data/models/stock_purchase_item.dart';
import '../../data/repos/products_repo.dart';
import '../../data/repos/stock_purchase_repo.dart';
import 'package:hesba/core/services/app_logger.dart';

/// شاشة تسجيل فاتورة شراء مخزون. متاحة لصاحب المحل وللحساب الفرعي
/// (النسخة المقيّدة لا تعرض أي بيانات سوى أسماء الأصناف المطلوبة للإدخال).
class AddStockPurchaseView extends StatefulWidget {
  final bool restricted;

  const AddStockPurchaseView({super.key, this.restricted = false});

  @override
  State<AddStockPurchaseView> createState() => _AddStockPurchaseViewState();
}

class _AddStockPurchaseViewState extends State<AddStockPurchaseView> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final List<_RowControllers> _rows = [_RowControllers()];

  List<Product> _products = [];
  StreamSubscription<List<Product>>? _productsSub;
  bool _loadingProducts = true;
  bool _saving = false;
  DateTime _date = DateTime.now();

  String? _ownerId;
  String? _shopId;
  String? _shopName;

  @override
  void initState() {
    super.initState();
    _resolveIds();
    _loadProducts();
  }

  Future<void> _resolveIds() async {
    final resolver = sl<ShopResolver>();
    _ownerId = resolver.currentUid;
    _shopId = await resolver.getShopId();
    _shopName = await resolver.getShopName();
    if (mounted) setState(() {});
  }

  void _loadProducts() {
    _productsSub = sl<ProductsRepo>().watchProducts().listen(
          (list) {
            if (!mounted) return;
            setState(() {
              _products = list;
              _loadingProducts = false;
            });
          },
          onError: (_) {
            if (mounted) setState(() => _loadingProducts = false);
          },
        );
  }

  double get _total => _rows.fold<double>(0, (sum, row) {
        final q = NumberParser.parseDouble(row.quantity.text);
        final c = NumberParser.parseDouble(row.cost.text);
        return sum + (q * c);
      });

  @override
  void dispose() {
    _productsSub?.cancel();
    _noteController.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) return;
    if (_shopId == null || _shopId!.isEmpty) {
      AppToast.error(context, 'لم يتم العثور على المتجر');
      return;
    }

    final items = <StockPurchaseItem>[];
    for (final row in _rows) {
      final q = NumberParser.parseDouble(row.quantity.text);
      final cost = NumberParser.parseDouble(row.cost.text);
      if (q <= 0) {
        AppToast.warning(context, 'الكمية يجب أن تكون أكبر من صفر');
        return;
      }
      if (cost < 0) {
        AppToast.warning(context, 'التكلفة غير صحيحة');
        return;
      }
      items.add(StockPurchaseItem(
        productId: row.product?.id ?? '',
        productName: row.name.text.trim(),
        quantity: q,
        unitCost: cost,
      ));
    }
    if (items.isEmpty) return;

    setState(() => _saving = true);
    try {
      await sl<StockPurchaseRepo>().addPurchase(
        ownerId: _ownerId ?? '',
        shopId: _shopId!,
        shopName: _shopName ?? '',
        items: items,
        totalAmount: _total,
        note: _noteController.text,
        date: _date,
      );
      if (mounted) {
        AppToast.success(context, 'تم تسجيل فاتورة الشراء');
        Navigator.pop(context, true);
      }
    } catch (e, logSt) {
      AppLogger.nonFatal('features/products/presentation/views/add_stock_purchase_view.dart', e, logSt, severity: LoggingSeverity.error);
      if (mounted) AppToast.error(context, _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(String msg) {
    if (msg.contains('permission-denied')) {
      return 'ليست لديك صلاحية لتسجيل الشراء (اشتراك المحل غير فعّال أو الحساب موقوف)';
    }
    return msg.replaceAll(RegExp(r'^Exception:\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('شراء مخزون جديد'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Text('التاريخ: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _date = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: const Text('تغيير التاريخ'),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Text('الأصناف', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
                const Spacer(),
                if (_loadingProducts)
                  const LoadingWidget(size: 16, compact: true),
              ],
            ),
            SizedBox(height: 10.h),
            ...List.generate(_rows.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _PurchaseRowCard(
                  controllers: _rows[index],
                  index: index,
                  products: _products,
                  onDelete: _rows.length == 1
                      ? null
                      : () => setState(() {
                            _rows[index].dispose();
                            _rows.removeAt(index);
                          }),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: () => setState(() => _rows.add(_RowControllers())),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('إضافة صنف'),
            ),
            SizedBox(height: 20.h),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.successDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الإجمالي', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                  Text(_total.toStringAsFixed(2),
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: AppTheme.successDark)),
                ],
              ),
            ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.4))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 50.h,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('حفظ فاتورة الشراء', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowControllers {
  final name = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final cost = TextEditingController();
  Product? product;

  void dispose() {
    name.dispose();
    quantity.dispose();
    cost.dispose();
  }
}

class _PurchaseRowCard extends StatelessWidget {
  final _RowControllers controllers;
  final int index;
  final List<Product> products;
  final VoidCallback? onDelete;

  const _PurchaseRowCard({
    required this.controllers,
    required this.index,
    required this.products,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('الصنف ${index + 1}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: AppTheme.danger, size: 20.sp),
                ),
            ],
          ),
          Autocomplete<Product>(
            optionsBuilder: (text) {
              final q = text.text.trim().toLowerCase();
              if (q.isEmpty) return products.where((p) => p.isActive).toList();
              return products.where((p) => p.name.toLowerCase().contains(q)).toList();
            },
            displayStringForOption: (p) => p.name,
            onSelected: (p) {
              controllers.product = p;
              controllers.name.text = p.name;
              // لا نملأ سعر الشراء من تكلفة المنتج — التكلفة/الربح
              // بيانات سرية لصاحب المحل، والموظف يدخل سعر الشراء بنفسه.
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldFocusChanged) {
              if (controllers.name.text.isNotEmpty && controller.text.isEmpty) {
                controller.text = controllers.name.text;
              }
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                onTap: onFieldFocusChanged,
                decoration: const InputDecoration(
                  labelText: 'اسم الصنف',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'اختر صنفًا' : null,
                onChanged: (v) {
                  controllers.name.text = v;
                  if (controllers.product != null && controllers.product!.name != v) {
                    controllers.product = null;
                  }
                },
              );
            },
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers.quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'الكمية'),
                  validator: (v) {
                    final q = NumberParser.parseDouble(v ?? '');
                    return q > 0 ? null : 'أكبر من صفر';
                  },
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextFormField(
                  controller: controllers.cost,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'سعر الشراء'),
                  validator: (v) {
                    final c = NumberParser.parseDouble(v ?? '');
                    return c >= 0 ? null : 'غير صحيح';
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
