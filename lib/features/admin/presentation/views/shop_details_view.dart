import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';

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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final shop = shopSnap.data?.data();
        if (shop == null) {
          return const Scaffold(body: Center(child: Text('المحل غير موجود')));
        }
        final shopName = shop['shopName'] as String? ?? 'تفاصيل المحل';
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(shopName),
              bottom: const TabBar(
                tabs: [Tab(text: 'بيانات'), Tab(text: 'الاشتراك'), Tab(text: 'الإحصائيات')],
              ),
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Section(
                      title: 'بيانات المحل',
                      children: [
                        _Row('المالك', shop['ownerName']),
                        _Row('الهاتف', shop['phone'] ?? shop['shopPhone']),
                        _Row('النوع', shop['businessType']),
                        _Row('المدينة', shop['city']),
                        _Row('العنوان', shop['address']),
                      ],
                    ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: sl<AdminRepo>().getUserSubscription(ownerId),
                      builder: (context, subSnap) {
                        final sub = subSnap.data?.data();
                        return _Section(
                          title: 'الاشتراك',
                          children: [
                            _Row('الحالة', sub?['status']),
                            _Row('الباقة', sub?['plan']),
                            _Row('تاريخ البدء', _date(sub?['startDate'])),
                            _Row('تاريخ الانتهاء', _date(sub?['endDate'])),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _CountSection(
                      title: 'المنتجات',
                      query: FirebaseFirestore.instance.collection('products').where('shopId', isEqualTo: shopId),
                    ),
                    _CountSection(
                      title: 'المبيعات',
                      query: FirebaseFirestore.instance.collection('sales').where('shopId', isEqualTo: shopId),
                    ),
                    _CountSection(
                      title: 'المصروفات',
                      query: FirebaseFirestore.instance.collection('expenses').where('shopId', isEqualTo: shopId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _date(dynamic v) {
    if (v == null) return '-';
    if (v is Timestamp) return v.toDate().toString().substring(0, 10);
    return v.toString();
  }
}

class _CountSection extends StatelessWidget {
  const _CountSection({required this.title, required this.query});
  final String title;
  final Query<Map<String, dynamic>> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: query.limit(100).get(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return _Section(title: title, children: [_Row('العدد', count.toString())]);
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }
}
