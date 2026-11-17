import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/widgets/loading_widget.dart';

import '../../../../../common_imports.dart';
import '../../../../../core/models/product.dart';
import '../../widgets/sale_product_card.dart';

/// قسم الأصناف: عنوان + كروت الأصناف + زر "إضافة صنف".
class SaleItemsSection extends StatelessWidget {
  final bool isDark;
  final int itemsCount;
  final bool loadingProducts;
  final int availableActiveCount;
  final List<dynamic> items;
  final List<Product> availableProducts;
  final VoidCallback onAddItem;
  final void Function(int index) onRemoveItem;
  final void Function(int index, Product? product) onProductSelected;
  final VoidCallback onChanged;

  const SaleItemsSection({
    super.key,
    required this.isDark,
    required this.itemsCount,
    required this.loadingProducts,
    required this.availableActiveCount,
    required this.items,
    required this.availableProducts,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onProductSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'saleItemsTitle'.tr(),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.ink,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '$itemsCount',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const Spacer(),
            if (loadingProducts)
              const LoadingWidget(size: 16, compact: true)
            else
              Text(
                'saleAvailableStock'.tr(
                    namedArgs: {'n': '$availableActiveCount'}),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.mutedGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'saleSearchHint'.tr(),
          style: TextStyle(fontSize: 11.5.sp, color: AppTheme.mutedGray),
        ),
        SizedBox(height: 12.h),
        ...List.generate(items.length, (index) {
          final e = items[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: SaleProductCard(
              index: index,
              nameController: e.name,
              quantityController: e.quantity,
              priceController: e.price,
              availableProducts: availableProducts,
              selectedProduct: e.selectedProduct,
              onProductSelected: (p) => onProductSelected(index, p),
              onChanged: onChanged,
              onDelete: () => onRemoveItem(index),
            ),
          );
        }),
        InkWell(
          onTap: onAddItem,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.35),
                width: 1.4,
              ),
              color: AppTheme.primaryColor.withValues(alpha: 0.04),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 19.sp, color: AppTheme.primaryColor),
                SizedBox(width: 8.w),
                Text(
                  'saleAddAnother'.tr(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

