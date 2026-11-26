import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:easy_localization/easy_localization.dart';

/// هيدر تفاصيل المحل: الصورة + الاسم + الموقع + النوع + حالة النشاط.
class ShopDetailsHeaderCard extends StatelessWidget {
  const ShopDetailsHeaderCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.type,
    required this.city,
    required this.address,
    required this.phone,
    required this.isActive,
  });

  final String name;
  final String imageUrl;
  final String type;
  final String city;
  final String address;
  final String phone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AdminSpace.md, AdminSpace.md, AdminSpace.md, AdminSpace.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AdminRadius.header),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          AdminThumbnail(url: imageUrl, size: 72, icon: Icons.storefront_outlined, radius: 16),
          const SizedBox(width: AdminSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: AdminSpace.xs),
                if (city.isNotEmpty || address.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text([city, address].where((e) => e.isNotEmpty).join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                if (phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Directionality(
                          textDirection: ui.TextDirection.rtl,
                          child: Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AdminSpace.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (type.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AdminRadius.badge)),
                        child: Text(type,
                            style: const TextStyle(
                                color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AdminColors.success : Colors.grey,
                        borderRadius: BorderRadius.circular(AdminRadius.badge),
                      ),
                      child: Text(isActive ? 'نشط'.tr() : 'غير نشط'.tr(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
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
