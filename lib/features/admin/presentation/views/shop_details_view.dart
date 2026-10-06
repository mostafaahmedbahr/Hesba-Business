import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/views/admin_ui.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = (shop['shopName'] as String? ?? '').trim().isEmpty ? 'تفاصيل المحل' : shop['shopName'] as String;
    final imageUrl = (shop['shopImageUrl'] as String? ?? '').trim();
    final type = (shop['businessType'] as String? ?? '').trim();
    final city = (shop['city'] as String? ?? '').trim();
    final address = (shop['address'] as String? ?? '').trim();
    final phone = ((shop['shopPhone'] ?? shop['phone']) as String? ?? '').trim();
    final isActive = (shop['isActive'] as bool?) ?? true;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: 'نسخ المعرف',
              icon: const Icon(Icons.copy_outlined, size: 20),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: shopId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ معرف المحل'), duration: Duration(seconds: 1)),
                  );
                }
              },
            ),
          ],
          bottom: TabBar(
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontFamily: AppTheme.fontFamily),
            tabs: const [Tab(text: 'بيانات'), Tab(text: 'الاشتراك'), Tab(text: 'الإحصائيات')],
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
              createdAt: _fmtDate(shop['createdAt']),
              isDark: isDark,
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _InfoTab(),
                  _SubscriptionTab(),
                  _StatsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(dynamic v) {
    if (v == null) return '-';
    if (v is Timestamp) {
      final d = v.toDate();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    return v.toString();
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
    required this.createdAt,
    required this.isDark,
  });
  final String name;
  final String imageUrl;
  final String type;
  final String city;
  final String address;
  final String phone;
  final bool isActive;
  final String createdAt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl.isEmpty
                ? Container(
                    width: 72,
                    height: 72,
                    color: Colors.white.withValues(alpha: 0.18),
                    child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 36),
                  )
                : Image.network(
                    imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 72,
                      height: 72,
                      color: Colors.white.withValues(alpha: 0.18),
                      child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 36),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 4),
                if (city.isNotEmpty || address.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          [city, address].where((e) => e.isNotEmpty).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
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
                        Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (type.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text(type, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.successColor : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(isActive ? 'نشط' : 'غير نشط',
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

// ── Tabs (need shop from ancestor) ──────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab();

  @override
  Widget build(BuildContext context) {
    final details = context.findAncestorWidgetOfExactType<_DetailsScaffold>()!;
    final shop = details.shop;
    final shopId = details.shopId;
    final ownerId = details.ownerId;

    final rows = <({IconData icon, String label, String value})>[
      (icon: Icons.badge_outlined, label: 'معرف المحل', value: shopId),
      (icon: Icons.person_outline, label: 'معرف المالك', value: ownerId.isEmpty ? '-' : ownerId),
      (icon: Icons.phone_outlined, label: 'هاتف المحل', value: _str(shop['shopPhone'] ?? shop['phone'])),
      (icon: Icons.category_outlined, label: 'نوع النشاط', value: _str(shop['businessType'])),
      (icon: Icons.location_city_outlined, label: 'المدينة', value: _str(shop['city'])),
      (icon: Icons.home_outlined, label: 'العنوان', value: _str(shop['address'])),
      (icon: Icons.map_outlined, label: 'المنطقة', value: _str(shop['state'])),
      (icon: Icons.link_outlined, label: 'رابط الموقع', value: _str(shop['locationUrl'])),
      (icon: Icons.calendar_month_outlined, label: 'تاريخ الإنشاء', value: _fmtDate(shop['createdAt'])),
      (icon: Icons.update_outlined, label: 'آخر تحديث', value: _fmtDate(shop['updatedAt'])),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: [
        _Card(
          title: 'بيانات المحل',
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _InfoRow(icon: rows[i].icon, label: rows[i].label, value: rows[i].value, copyable: i < 2),
                if (i != rows.length - 1) const Divider(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _str(dynamic v) {
    final s = (v as String?)?.trim() ?? '';
    return s.isEmpty ? '-' : s;
  }

  String _fmtDate(dynamic v) => _DetailsScaffold._fmtDate(v);
}

class _SubscriptionTab extends StatelessWidget {
  const _SubscriptionTab();

  @override
  Widget build(BuildContext context) {
    final details = context.findAncestorWidgetOfExactType<_DetailsScaffold>()!;
    final ownerId = details.ownerId;

    if (ownerId.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [adminEmpty(Icons.workspace_premium_outlined, 'لا يوجد مالك مرتبط بهذا المحل')],
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: sl<AdminRepo>().getUserSubscription(ownerId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return adminSkeletonList(context, count: 3);
        }
        final sub = snap.data?.data();
        if (sub == null || sub.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [adminEmpty(Icons.workspace_premium_outlined, 'لا يوجد اشتراك لهذا المحل')],
          );
        }
        final status = (sub['status'] as String?) ?? '-';
        final plan = _planName(sub['plan']);
        final isTrial = (sub['isTrial'] as bool?) ?? false;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          children: [
            _Card(
              title: 'حالة الاشتراك',
              trailing: AdminStatusBadge.status(status),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.workspace_premium_outlined, label: 'الباقة', value: plan),
                  const Divider(height: 14),
                  _InfoRow(icon: Icons.timelapse_outlined, label: 'تجريبي', value: isTrial ? 'نعم' : 'لا'),
                  const Divider(height: 14),
                  _InfoRow(icon: Icons.play_arrow_outlined, label: 'تاريخ البدء', value: _fmtDate(sub['startDate'])),
                  const Divider(height: 14),
                  _InfoRow(icon: Icons.stop_outlined, label: 'تاريخ الانتهاء', value: _fmtDate(sub['endDate'])),
                  const Divider(height: 14),
                  _InfoRow(icon: Icons.update_outlined, label: 'آخر تحديث', value: _fmtDate(sub['updatedAt'])),
                  if ((sub['lastRequestId'] as String?)?.isNotEmpty ?? false) ...[
                    const Divider(height: 14),
                    _InfoRow(icon: Icons.receipt_long_outlined, label: 'آخر طلب', value: sub['lastRequestId'].toString()),
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

  String _fmtDate(dynamic v) => _DetailsScaffold._fmtDate(v);
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    final details = context.findAncestorWidgetOfExactType<_DetailsScaffold>()!;
    final shopId = details.shopId;
    final db = FirebaseFirestore.instance;

    final items = [
      (title: 'المنتجات', icon: Icons.inventory_2_outlined, color: AppTheme.primaryColor,
        query: db.collection('products').where('shopId', isEqualTo: shopId)),
      (title: 'المبيعات', icon: Icons.point_of_sale_outlined, color: AppTheme.successColor,
        query: db.collection('sales').where('shopId', isEqualTo: shopId)),
      (title: 'المصروفات', icon: Icons.money_off_outlined, color: Colors.redAccent,
        query: db.collection('expenses').where('shopId', isEqualTo: shopId)),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final it = items[i];
        return _Card(
          title: it.title,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: it.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(it.icon, color: it.color, size: 22),
          ),
          child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: it.query.limit(1000).count().get().then((_) => it.query.limit(100).get()),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 4),
                );
              }
              final count = snap.data?.docs.length ?? 0;
              final capped = count >= 100 ? '100+' : '$count';
              return Row(
                children: [
                  Text(capped, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  Text(count >= 100 ? 'عنصر (حد العرض 100)' : 'عنصر', style: Theme.of(context).textTheme.bodySmall),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ── Shared UI ───────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing, this.leading});
  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.black.withValues(alpha: 0.06)),
        boxShadow: isDark ? null : AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading case final l?) ...[l, const SizedBox(width: 10)],
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.copyable = false});
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = isDark ? AppTheme.darkTextSecondary : Colors.grey[600];
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: sub, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (copyable && value != '-')
          IconButton(
            tooltip: 'نسخ',
            icon: const Icon(Icons.copy_outlined, size: 17),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم النسخ'), duration: Duration(seconds: 1)),
                );
              }
            },
          ),
      ],
    );
  }
}
