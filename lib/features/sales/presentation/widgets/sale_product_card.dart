import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/models/product.dart';

class SaleProductCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final VoidCallback onDelete;
  final List<Product> availableProducts;
  final Product? selectedProduct;
  final ValueChanged<Product?> onProductSelected;
  final VoidCallback onChanged;

  const SaleProductCard({
    super.key,
    required this.nameController,
    required this.quantityController,
    required this.priceController,
    required this.onDelete,
    required this.availableProducts,
    required this.selectedProduct,
    required this.onProductSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 18.sp,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'المنتج',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selectedProduct != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: selectedProduct!.isOutOfStock
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'متاح: ${selectedProduct!.stock}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: selectedProduct!.isOutOfStock
                          ? Colors.red
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade400,
                tooltip: 'حذف',
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Autocomplete for product selection
          Autocomplete<Product>(
            displayStringForOption: (p) => p.name,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return availableProducts.take(6);
              }
              final q = textEditingValue.text.toLowerCase();
              return availableProducts.where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.code.toLowerCase().contains(q) ||
                  p.category.toLowerCase().contains(q));
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12.r),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200.h, maxWidth: 340.w),
                    child: ListView.separated(
                      padding: EdgeInsets.all(6.w),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => Divider(height: 1.h),
                      itemBuilder: (context, index) {
                        final p = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(p.name,
                              style: TextStyle(
                                  fontSize: 13.sp, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${p.code.isNotEmpty ? '${p.code} • ' : ''}${p.price.toStringAsFixed(0)} ج.م • مخزون: ${p.stock}',
                              style: TextStyle(fontSize: 11.sp)),
                          trailing: p.isLowStock
                              ? Icon(Icons.warning_amber_rounded,
                                  size: 16.sp, color: Colors.orange)
                              : null,
                          onTap: () => onSelected(p),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder:
                (context, textController, focusNode, onFieldSubmitted) {
              // Sync external controller with internal one
              // We use nameController as source of truth, so mirror it
              textController.text = nameController.text;
              textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: textController.text.length));

              // Listen to keep them in sync (one way)
              textController.addListener(() {
                if (nameController.text != textController.text) {
                  nameController.text = textController.text;
                  onChanged();
                }
              });

              return TextFormField(
                controller: textController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'اسم المنتج / ابحث من المخزون',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: textController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            textController.clear();
                            nameController.clear();
                            onProductSelected(null);
                            onChanged();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              );
            },
            onSelected: (product) {
              nameController.text = product.name;
              priceController.text =
                  product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2);
              if (quantityController.text.isEmpty) {
                quantityController.text = '1';
              }
              onProductSelected(product);
              onChanged();
            },
          ),

          if (selectedProduct != null) ...[
            SizedBox(height: 6.h),
            Text(
              '${selectedProduct!.category.isNotEmpty ? '${selectedProduct!.category} • ' : ''}سعر الشراء: ${selectedProduct!.costPrice.toStringAsFixed(0)} ج.م',
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'الكمية',
                    hintText: '1',
                    prefixIcon: const Icon(Icons.numbers_rounded),
                    border: const OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  ),
                  onChanged: (_) => onChanged(),
                  validator: (v) {
                    final q = double.tryParse(v ?? '');
                    if (q == null || q <= 0) return '>';
                    if (selectedProduct != null &&
                        q > selectedProduct!.stock) {
                      return 'المتاح ${selectedProduct!.stock}';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextFormField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'سعر الوحدة',
                    hintText: '0',
                    suffixText: 'ج.م',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: const OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  ),
                  onChanged: (_) => onChanged(),
                  validator: (v) {
                    final p = double.tryParse(v ?? '');
                    if (p == null || p <= 0) return '>';
                    return null;
                  },
                ),
              ),
            ],
          ),

          // Live line total
          SizedBox(height: 8.h),
          Builder(builder: (context) {
            final q = double.tryParse(quantityController.text) ?? 0;
            final p = double.tryParse(priceController.text) ?? 0;
            final lineTotal = q * p;
            if (lineTotal <= 0) return const SizedBox.shrink();
            return Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                'الإجمالي: ${lineTotal.toStringAsFixed(2)} ج.م',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
