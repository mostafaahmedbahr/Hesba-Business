import 'package:flutter/material.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/presentation/widgets/shop_details/header_card.dart';
import 'package:hesba/features/admin/presentation/widgets/shop_details/overview_tab.dart';
import 'package:hesba/features/admin/presentation/widgets/shop_details/shop_items_tab.dart';
import 'package:hesba/features/admin/presentation/widgets/shop_details/subscription_tab.dart';
import 'package:easy_localization/easy_localization.dart';

/// Scaffold تفاصيل المحل: الهيدر + تبويبات (نظرة عامة / منتجات / مبيعات / مصروفات / اشتراك).
class ShopDetailsScaffold extends StatelessWidget {
  const ShopDetailsScaffold({
    super.key,
    required this.shop,
    required this.shopId,
    required this.ownerId,
  });

  final Map<String, dynamic> shop;
  final String shopId;
  final String ownerId;

  @override
  Widget build(BuildContext context) {
    final name = (shop['shopName'] as String? ?? '').trim().isEmpty ? 'تفاصيل المحل'.tr() : shop['shopName'] as String;
    final imageUrl = (shop['shopImageUrl'] as String? ?? '').trim();
    final type = (shop['businessType'] as String? ?? '').trim();
    final city = (shop['city'] as String? ?? '').trim();
    final address = (shop['address'] as String? ?? '').trim();
    final phone = ((shop['shopPhone'] ?? shop['phone']) as String? ?? '').trim();
    final isActive = (shop['isActive'] as bool?) ?? true;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: 'نسخ معرف المحل'.tr(),
              icon: const Icon(Icons.copy_outlined, size: 20),
              onPressed: () => CopyableId.copy(context, shopId),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontFamily: AppTheme.fontFamily),
            tabs: [
              Tab(text: 'نظرة عامة'.tr()),
              Tab(text: 'المنتجات'.tr()),
              Tab(text: 'المبيعات'.tr()),
              Tab(text: 'المصروفات'.tr()),
              Tab(text: 'الاشتراك'.tr()),
            ],
          ),
        ),
        body: Column(
          children: [
            ShopDetailsHeaderCard(
              name: name,
              imageUrl: imageUrl,
              type: type,
              city: city,
              address: address,
              phone: phone,
              isActive: isActive,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ShopOverviewTab(shop: shop, shopId: shopId, ownerId: ownerId),
                  ShopItemsTab(collection: 'products', shopId: shopId),
                  ShopItemsTab(collection: 'sales', shopId: shopId),
                  ShopItemsTab(collection: 'expenses', shopId: shopId),
                  ShopSubscriptionTab(ownerId: ownerId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
