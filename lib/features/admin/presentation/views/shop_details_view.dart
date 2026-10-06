import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

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
            appBar: AppBar(title: const Text('تفاصيل المحل')),
            body: adminSkeletonList(context),
          );
        }
        if (shopSnap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المحل')),
            body: adminError('تعذر تحميل بيانات المحل', () => (context as Element).markNeedsBuild()),
          );
        }
        final shop = shopSnap.data?.data();
        if (shop == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المحل')),
            body: adminEmpty(Icons.storefront_outlined, 'المحل غير موجود'),
          );
        }
        return _DetailsScaffold(shop: shop, shopId: shopId, ownerId: ownerId);
      },
    );
  }
}

class _DetailsScaffold extends StatelessWidget {
  const _DetailsScaffold({required this.shop, required this.shopId, required this.ownerId});
  final Map<String, dynamic> shop;
  final String shopId;
  final String ownerId;

  @override
  Widget build(BuildContext context) {
    final name = (shop['shopName'] as String? ?? '').trim().isEmpty ? 'تفاصيل المحل' : shop['shopName'] as String;
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
              tooltip: 'نسخ معرف المحل',
              icon: const Icon(Icons.copy_outlined, size: 20),
              onPressed: () => CopyableId.copy(context, shopId),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontFamily: AppTheme.fontFamily),
            tabs: [
              Tab(text: 'نظرة عامة'),
              Tab(text: 'المنتجات'),
              Tab(text: 'المبيعات'),
              Tab(text: 'المصروفات'),
              Tab(text: 'الاشتراك'),
            ],
          ),
        ),
        body: Column(
          children: [
            _HeaderCard(
              name: name,
              imageUrl: imageUrl,
              type: type,
              city: city,
              address: address,
              phone: phone,
              isActive: isActive,
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(),
                  _ShopItemsTab(collection: 'products'),
                  _ShopItemsTab(collection: 'sales'),
                  _ShopItemsTab(collection: 'expenses'),
                  _SubscriptionTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
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
                          textDirection: TextDirection.rtl,
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
                      child:
                          Text(isActive ? 'نشط' : 'غير نشط', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
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

// ── Overview ────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final details = context.findAncestorWidgetOfExactType<_DetailsScaffold>()!;
    final shop = details.shop;
    final shopId = details.shopId;
    final ownerId = details.ownerId;

    String str(dynamic v) {
      final s = (v as String?)?.trim() ?? '';
      return s.isEmpty ? '-' : s;
    }

    void goTab(int i) => DefaultTabController.of(context).animateTo(i);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AdminSpace.md, AdminSpace.xs, AdminSpace.md, AdminSpace.lg),
      children: [
        AdminSection(
          title: 'المعرفات',
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              CopyableId(id: shopId, full: true, label: 'معرف المحل'),
              const Divider(height: 20),
              if (ownerId.isEmpty)
                const AdminInfoRow(icon: Icons.person_outline, label: 'معرف المالك', value: '-')
              else
                CopyableId(id: ownerId, full: true, label: 'معرف المالك'),
            ],
          ),
        ),
        const SizedBox(height: AdminSpace.md),
        AdminSection(
          title: 'بيانات المحل',
          icon: Icons.storefront_outlined,
          child: Column(
            children: [
              AdminInfoRow(icon: Icons.phone_outlined, label: 'هاتف المحل', value: str(shop['shopPhone'] ?? shop['phone'])),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.category_outlined, label: 'نوع النشاط', value: str(shop['businessType'])),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.location_city_outlined, label: 'المدينة', value: str(shop['city'])),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.home_outlined, label: 'العنوان', value: str(shop['address'])),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.map_outlined, label: 'المنطقة', value: str(shop['state'])),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.link_outlined, label: 'رابط الموقع', value: str(shop['locationUrl'])),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.calendar_month_outlined, label: 'تاريخ الإنشاء', value: AdminFmt.date(shop['createdAt'])),
              const Divider(height: 14),
              AdminInfoRow(icon: Icons.update_outlined, label: 'آخر تحديث', value: AdminFmt.date(shop['updatedAt'])),
            ],
          ),
        ),
        const SizedBox(height: AdminSpace.md),
        _SubscriptionSummary(ownerId: ownerId),
        const SizedBox(height: AdminSpace.md),
        Row(
          children: [
            Expanded(child: _CountTile(title: 'المنتجات', icon: Icons.inventory_2_outlined, color: AppTheme.primaryColor, collection: 'products', shopId: shopId, tab: 1, onGo: goTab)),
            const SizedBox(width: AdminSpace.md),
            Expanded(child: _CountTile(title: 'المبيعات', icon: Icons.point_of_sale_outlined, color: AdminColors.success, collection: 'sales', shopId: shopId, tab: 2, onGo: goTab)),
            const SizedBox(width: AdminSpace.md),
            Expanded(child: _CountTile(title: 'المصروفات', icon: Icons.money_off_outlined, color: AdminColors.error, collection: 'expenses', shopId: shopId, tab: 3, onGo: goTab)),
          ],
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.title, required this.icon, required this.color, required this.collection, required this.shopId, required this.tab, required this.onGo});
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
      child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection(collection).where('shopId', isEqualTo: shopId).limit(100).get(),
        builder: (context, snap) {
          final count = snap.data?.docs.length ?? 0;
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

class _SubscriptionSummary extends StatelessWidget {
  const _SubscriptionSummary({required this.ownerId});
  final String ownerId;

  @override
  Widget build(BuildContext context) {
    if (ownerId.isEmpty) {
      return AdminSection(
        title: 'الاشتراك',
        icon: Icons.workspace_premium_outlined,
        child: adminEmpty(Icons.workspace_premium_outlined, 'لا يوجد مالك مرتبط'),
      );
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: sl<AdminRepo>().getUserSubscription(ownerId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AdminSection(title: 'الاشتراك', icon: Icons.workspace_premium_outlined, child: LinearProgressIndicator(minHeight: 4));
        }
        final sub = snap.data?.data();
        if (sub == null || sub.isEmpty) {
          return AdminSection(
            title: 'الاشتراك',
            icon: Icons.workspace_premium_outlined,
            child: adminEmpty(Icons.workspace_premium_outlined, 'لا يوجد اشتراك'),
          );
        }
        final status = (sub['status'] as String?) ?? '';
        return AdminSection(
          title: 'الاشتراك',
          icon: Icons.workspace_premium_outlined,
          trailing: AdminStatusBadge.status(status),
          child: AdminInfoRow(icon: Icons.play_arrow_outlined, label: 'المدة', value: '${AdminFmt.dateNum(sub['startDate'])} → ${AdminFmt.dateNum(sub['endDate'])}'),
        );
      },
    );
  }
}

// ── Items tabs (products / sales / expenses) ─────────────

class _ShopItemsTab extends StatelessWidget {
  const _ShopItemsTab({required this.collection});
  final String collection;

  @override
  Widget build(BuildContext context) {
    final shopId = context.findAncestorWidgetOfExactType<_DetailsScaffold>()!.shopId;
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection(collection).where('shopId', isEqualTo: shopId).limit(50).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return adminSkeletonList(context, count: 4);
        if (snap.hasError) return adminError('تعذر تحميل البيانات', () => (context as Element).markNeedsBuild());
        final docs = [...(snap.data?.docs ?? [])]
          ..sort((a, b) {
            final da = AdminFmt.toDate(a.data()['createdAt']);
            final db = AdminFmt.toDate(b.data()['createdAt']);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
        if (docs.isEmpty) {
          return adminEmpty(
            collection == 'products' ? Icons.inventory_2_outlined : collection == 'sales' ? Icons.point_of_sale_outlined : Icons.money_off_outlined,
            'لا توجد عناصر',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AdminSpace.md, AdminSpace.xs, AdminSpace.md, AdminSpace.lg),
          itemCount: docs.length + 1,
          separatorBuilder: (_, i) => const SizedBox(height: AdminSpace.sm),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AdminSpace.xs),
                child: Text('العدد: ${docs.length}${docs.length >= 50 ? ' (أول 50)' : ''}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AdminColors.textSecondary(context), fontWeight: FontWeight.w700)),
              );
            }
            final d = docs[i - 1];
            return _itemRow(context, d.id, d.data());
          },
        );
      },
    );
  }

  Widget _itemRow(BuildContext context, String id, Map<String, dynamic> data) {
    switch (collection) {
      case 'products':
        return AdminCard(
          padding: const EdgeInsets.all(AdminSpace.md),
          child: Row(
            children: [
              AdminThumbnail(url: (data['imageUrl'] as String?) ?? '', size: 46, icon: Icons.inventory_2_outlined),
              const SizedBox(width: AdminSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((data['name'] as String?) ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text('${data['category'] ?? '-'} • الكمية: ${data['stock'] ?? 0}',
                        style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12)),
                    const SizedBox(height: 2),
                    CopyableId(id: id),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AdminRadius.tag)),
                child: Text(AdminFmt.money((data['price'] as num?) ?? 0),
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
            ],
          ),
        );
      case 'sales':
        return AdminCard(
          padding: const EdgeInsets.all(AdminSpace.md),
          child: Row(
            children: [
              const AdminIconTile(icon: Icons.point_of_sale_outlined, color: AdminColors.success, size: 46),
              const SizedBox(width: AdminSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AdminFmt.money((data['total'] as num?) ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${AdminFmt.dateNum(data['createdAt'])}${data['paymentMethod'] != null ? ' • ${data['paymentMethod']}' : ''}',
                        style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12)),
                    const SizedBox(height: 2),
                    CopyableId(id: id),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return AdminCard(
          padding: const EdgeInsets.all(AdminSpace.md),
          child: Row(
            children: [
              const AdminIconTile(icon: Icons.money_off_outlined, color: AdminColors.error, size: 46),
              const SizedBox(width: AdminSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((data['title'] as String?) ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text('${data['category'] ?? '-'} • ${AdminFmt.dateNum(data['createdAt'] ?? data['date'])}',
                        style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12)),
                    const SizedBox(height: 2),
                    CopyableId(id: id),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AdminColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AdminRadius.tag)),
                child: Text(AdminFmt.money((data['amount'] as num?) ?? 0),
                    style: const TextStyle(color: AdminColors.error, fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
            ],
          ),
        );
    }
  }
}

// ── Subscription tab ──────────────────────────────────────

class _SubscriptionTab extends StatelessWidget {
  const _SubscriptionTab();

  @override
  Widget build(BuildContext context) {
    final ownerId = context.findAncestorWidgetOfExactType<_DetailsScaffold>()!.ownerId;
    if (ownerId.isEmpty) {
      return adminEmpty(Icons.workspace_premium_outlined, 'لا يوجد مالك مرتبط بهذا المحل');
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: sl<AdminRepo>().getUserSubscription(ownerId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return adminSkeletonList(context, count: 3);
        final sub = snap.data?.data();
        if (sub == null || sub.isEmpty) {
          return adminEmpty(Icons.workspace_premium_outlined, 'لا يوجد اشتراك لهذا المحل');
        }
        final status = (sub['status'] as String?) ?? '-';
        final plan = _planName(sub['plan']);
        final isTrial = (sub['isTrial'] as bool?) ?? false;
        return ListView(
          padding: const EdgeInsets.fromLTRB(AdminSpace.md, AdminSpace.xs, AdminSpace.md, AdminSpace.lg),
          children: [
            AdminSection(
              title: 'حالة الاشتراك',
              icon: Icons.workspace_premium_outlined,
              trailing: AdminStatusBadge.status(status),
              child: Column(
                children: [
                  AdminInfoRow(icon: Icons.workspace_premium_outlined, label: 'الباقة', value: plan),
                  const Divider(height: 14),
                  AdminInfoRow(icon: Icons.timelapse_outlined, label: 'تجريبي', value: isTrial ? 'نعم' : 'لا'),
                  const Divider(height: 14),
                  AdminInfoRow(icon: Icons.play_arrow_outlined, label: 'تاريخ البدء', value: AdminFmt.date(sub['startDate'])),
                  const Divider(height: 14),
                  AdminInfoRow(icon: Icons.stop_outlined, label: 'تاريخ الانتهاء', value: AdminFmt.date(sub['endDate'])),
                  const Divider(height: 14),
                  AdminInfoRow(icon: Icons.update_outlined, label: 'آخر تحديث', value: AdminFmt.date(sub['updatedAt'])),
                  if ((sub['lastRequestId'] as String?)?.isNotEmpty ?? false) ...[
                    const Divider(height: 14),
                    AdminInfoRow(icon: Icons.receipt_long_outlined, label: 'آخر طلب', value: sub['lastRequestId'].toString(), copyable: true),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _planName(dynamic p) {
    if (p == null) return '-';
    if (p is String) return p.isEmpty ? '-' : p;
    if (p is Map) return (p['id'] ?? p['name'] ?? '-').toString();
    return p.toString();
  }
}
