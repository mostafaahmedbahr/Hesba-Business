import 'package:flutter/material.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/presentation/widgets/shop_details/count_tile.dart';
import 'package:hesba/features/admin/presentation/widgets/shop_details/shop_location_row.dart';
import 'package:hesba/features/admin/presentation/widgets/shop_details/subscription_summary.dart';
import 'package:easy_localization/easy_localization.dart';

/// تاب «نظرة عامة»: المعرفات + بيانات المحل + ملخص الاشتراك + العدّادات.
class ShopOverviewTab extends StatelessWidget {
  const ShopOverviewTab({
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
    String str(dynamic v) {
      final s = (v as String?)?.trim() ?? '';
      return s.isEmpty ? '-' : s;
    }

    /// أول قيمة نصية موجودة من القيم المُمرَّرة (للتراجع بين حقول قديمة/جديدة).
    String firstText(List<dynamic> values) {
      for (final value in values) {
        final s = (value as String?)?.trim() ?? '';
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    void goTab(int i) => DefaultTabController.of(context).animateTo(i);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AdminSpace.md, AdminSpace.xs, AdminSpace.md, AdminSpace.lg),
      children: [
        AdminSection(
          title: 'المعرفات'.tr(),
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              CopyableId(id: shopId, full: true, label: 'معرف المحل'.tr()),
              const Divider(height: 20),
              if (ownerId.isEmpty)
                AdminInfoRow(icon: Icons.person_outline, label: 'معرف المالك'.tr(), value: '-')
              else
                CopyableId(id: ownerId, full: true, label: 'معرف المالك'.tr()),
            ],
          ),
        ),
        const SizedBox(height: AdminSpace.md),
        AdminSection(
          title: 'بيانات المحل'.tr(),
          icon: Icons.storefront_outlined,
          child: Column(
            children: [
              AdminInfoRow(icon: Icons.phone_outlined, label: 'هاتف المحل'.tr(), value: str(shop['shopPhone'] ?? shop['phone'])),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.category_outlined, label: 'نوع النشاط'.tr(), value: str(shop['businessType']).tr()),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.location_city_outlined, label: 'المدينة'.tr(), value: str(shop['city']).tr()),
              const Divider(height: 14),
              AdminInfoRow(
                icon: Icons.home_outlined,
                label: 'العنوان'.tr(),
                value: str(firstText([shop['address'], shop['locationAddress']])),
              ),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.map_outlined, label: 'المنطقة'.tr(), value: str(shop['state']).tr()),
              const Divider(height: 14),
              ShopLocationRow(shop: shop),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.calendar_month_outlined, label: 'تاريخ الإنشاء'.tr(), value: AdminFmt.date(shop['createdAt'])),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.update_outlined, label: 'آخر تحديث'.tr(), value: AdminFmt.date(shop['updatedAt'])),
            ],
          ),
        ),
        const SizedBox(height: AdminSpace.md),
        ShopSubscriptionSummary(ownerId: ownerId),
        const SizedBox(height: AdminSpace.md),
        Row(
          children: [
            Expanded(child: ShopCountTile(title: 'المنتجات'.tr(), icon: Icons.inventory_2_outlined, color: AppTheme.primaryColor, collection: 'products', shopId: shopId, tab: 1, onGo: goTab)),
            const SizedBox(width: AdminSpace.md),
            Expanded(child: ShopCountTile(title: 'المبيعات'.tr(), icon: Icons.point_of_sale_outlined, color: AdminColors.success, collection: 'sales', shopId: shopId, tab: 2, onGo: goTab)),
            const SizedBox(width: AdminSpace.md),
            Expanded(child: ShopCountTile(title: 'المصروفات'.tr(), icon: Icons.money_off_outlined, color: AdminColors.error, collection: 'expenses', shopId: shopId, tab: 3, onGo: goTab)),
          ],
        ),
      ],
    );
  }
}
