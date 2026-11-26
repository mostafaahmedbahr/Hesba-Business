import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/widgets/loading_widget.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/presentation/widgets/shop_details/details_scaffold.dart';
import 'package:easy_localization/easy_localization.dart';

/// شاشة تفاصيل المحل (أدمن): تحمّل المستند ثم تعرض الهيكل الكامل.
class ShopDetailsView extends StatelessWidget {
  const ShopDetailsView({super.key, required this.shopId, required this.ownerId});

  final String shopId;
  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: sl<AdminRepo>().getShop(shopId),
      builder: (context, shopSnap) {
        if (shopSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('تفاصيل المحل'.tr())),
            body: const LoadingWidget(),
          );
        }
        if (shopSnap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('تفاصيل المحل'.tr())),
            body: adminError('تعذر تحميل بيانات المحل'.tr(), () => (context as Element).markNeedsBuild()),
          );
        }
        final shop = shopSnap.data?.data();
        if (shop == null) {
          return Scaffold(
            appBar: AppBar(title: Text('تفاصيل المحل'.tr())),
            body: adminEmpty(Icons.storefront_outlined, 'المحل غير موجود'.tr()),
          );
        }
        return ShopDetailsScaffold(shop: shop, shopId: shopId, ownerId: ownerId);
      },
    );
  }
}
