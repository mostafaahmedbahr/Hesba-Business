import 'package:flutter/material.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/core/theme/app_theme.dart';

class ProductDetailsView extends StatelessWidget {
  const ProductDetailsView({super.key, required this.data, required this.id});

  final Map<String, dynamic> data;
  final String id;

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] as String?) ?? 'تفاصيل المنتج';
    final imageUrl = (data['imageUrl'] as String?) ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'نسخ معرف المنتج',
            icon: const Icon(Icons.copy_outlined, size: 20),
            onPressed: () => CopyableId.copy(context, id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AdminSpace.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AdminSpace.lg),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AdminRadius.header),
              boxShadow: AppTheme.cardShadow(context),
            ),
            child: Row(
              children: [
                AdminThumbnail(url: imageUrl, size: 76, icon: Icons.inventory_2_outlined, radius: 16),
                const SizedBox(width: AdminSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text((data['category'] as String?) ?? '-',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AdminRadius.badge)),
                        child: Text(AdminFmt.money((data['price'] as num?) ?? 0),
                            style: const TextStyle(
                                color: AppTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AdminSpace.md),
          AdminSection(
            title: 'المعرفات',
            icon: Icons.badge_outlined,
            child: Column(
              children: [
                CopyableId(id: id, full: true, label: 'معرف المنتج'),
                const Divider(height: 20),
                if (((data['shopId'] as String?) ?? '').isNotEmpty)
                  CopyableId(id: data['shopId'] as String, full: true, label: 'معرف المحل')
                else
                  const AdminInfoRow(icon: Icons.storefront_outlined, label: 'معرف المحل', value: '-'),
              ],
            ),
          ),
          const SizedBox(height: AdminSpace.md),
          AdminSection(
            title: 'بيانات المنتج',
            icon: Icons.inventory_2_outlined,
            child: Column(
              children: [
                AdminInfoRow(icon: Icons.category_outlined, label: 'التصنيف', value: (data['category'] as String?) ?? '-'),
                const Divider(height: 14),
                AdminInfoRow(
                    icon: Icons.payments_outlined, label: 'السعر', value: AdminFmt.money((data['price'] as num?) ?? 0)),
                const Divider(height: 14),
                AdminInfoRow(
                    icon: Icons.inventory_outlined, label: 'الكمية بالمخزون', value: '${data['stock'] ?? 0}'),
                const Divider(height: 14),
                AdminInfoRow(
                    icon: Icons.calendar_month_outlined, label: 'تاريخ الإضافة', value: AdminFmt.date(data['createdAt'])),
                const Divider(height: 14),
                AdminInfoRow(icon: Icons.update_outlined, label: 'آخر تحديث', value: AdminFmt.date(data['updatedAt'])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
