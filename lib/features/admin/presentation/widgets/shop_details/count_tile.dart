import 'package:flutter/material.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

/// كارت عدّاد صغير (المنتجات / المبيعات / المصروفات) مع انتقال للتاب المقابل.
class ShopCountTile extends StatelessWidget {
  const ShopCountTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.collection,
    required this.shopId,
    required this.tab,
    required this.onGo,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String collection;
  final String shopId;
  final int tab;
  final ValueChanged<int> onGo;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: () => onGo(tab),
      child: FutureBuilder<int>(
        future: sl<AdminRepo>().countShopDocs(collection: collection, shopId: shopId),
        builder: (context, snap) {
          final count = snap.data ?? 0;
          final capped = snap.connectionState == ConnectionState.waiting ? '…' : (count >= 100 ? '100+' : '$count');
          return Column(
            children: [
              AdminIconTile(icon: icon, color: color, size: 38),
              const SizedBox(height: AdminSpace.sm),
              Text(capped, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary(context))),
            ],
          );
        },
      ),
    );
  }
}
