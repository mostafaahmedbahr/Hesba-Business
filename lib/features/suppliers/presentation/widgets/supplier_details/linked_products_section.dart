import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/models/product.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../states/supplier_details_state.dart';
import 'section_card.dart';

/// قسم المنتجات المرتبطة بالمورد (قائمة أو حالة فارغة).
class SupplierLinkedProductsSection extends StatelessWidget {
  final SupplierDetailsState state;
  final bool isDark;
  const SupplierLinkedProductsSection({
    super.key,
    required this.state,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final products = state.linkedProducts;
    return SupplierSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 17.sp,
                color: AppTheme.violetDeep,
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  'supplierLinkedProducts'.tr(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.ink,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.violetDeep.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppTheme.violetDeep.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  'supplierLinkedCount'.tr(args: ['${state.linkedCount}']),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.violetDeep,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (products.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 30.sp,
                    color: AppTheme.mutedGray,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'supplierNoLinkedProducts'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.ink,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'supplierNoLinkedProductsHint'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.mutedGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < products.length; i++) ...[
                  if (i > 0) SizedBox(height: 8.h),
                  _LinkedProductTile(product: products[i], isDark: isDark),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _LinkedProductTile extends StatelessWidget {
  final Product product;
  final bool isDark;
  const _LinkedProductTile({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final image = product.imageUrl.trim();
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: image.isEmpty
                ? Icon(
                    Icons.inventory_2_rounded,
                    size: 20.sp,
                    color: AppTheme.violetSoft,
                  )
                : CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Icon(
                      Icons.inventory_2_rounded,
                      size: 20.sp,
                      color: AppTheme.violetSoft,
                    ),
                  ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.ink,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      'supplierProductPrice'.tr(
                        args: [
                          product.price.toStringAsFixed(
                            product.price % 1 == 0 ? 0 : 2,
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successDark,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'supplierProductStock'.tr(
                        args: [
                          product.stock.toStringAsFixed(
                            product.stock % 1 == 0 ? 0 : 2,
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slateGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
