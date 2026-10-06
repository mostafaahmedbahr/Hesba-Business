import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hesba/core/theme/app_theme.dart';

import 'admin_ds.dart';

class ActivityView extends StatefulWidget {
  const ActivityView({super.key});

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  String _group = 'all';

  bool _matches(String action) {
    return switch (_group) {
      'all' => true,
      'subs' => action.contains('subscription'),
      'shops' => action.contains('shop'),
      'products' => action.contains('product'),
      'sales' => action.contains('sale'),
      'expenses' => action.contains('expense'),
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('activity_logs').orderBy('createdAt', descending: true).limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              const AdminPageHeader(title: 'النشاطات', description: 'سجل عمليات النظام والإدارة'),
              Expanded(child: adminSkeletonList(context)),
            ],
          );
        }
        if (snapshot.hasError) {
          return adminError('تعذر تحميل سجل النشاط', () => setState(() {}));
        }
        final all = snapshot.data?.docs ?? [];
        final docs = all.where((d) => _matches((d.data()['action'] as String?) ?? '')).toList();

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Column(
            children: [
              const AdminPageHeader(title: 'النشاطات', description: 'سجل عمليات النظام والإدارة (آخر 100 عملية)'),
              AdminSummaryHeader(
                icon: Icons.history_outlined,
                title: 'إجمالي العمليات',
                total: all.length,
                unit: 'عملية',
                stats: [if (_group != 'all') 'عرض ${docs.length} من ${all.length}' else 'الكل معروض'],
                onRefresh: () => setState(() {}),
              ),
              AdminFilterChips(
                selected: _group,
                onSelect: (k) => setState(() => _group = k),
                items: const [
                  AdminChipItem('all', 'الكل'),
                  AdminChipItem('subs', 'الاشتراكات', dot: AppTheme.primaryColor),
                  AdminChipItem('shops', 'المحلات', dot: AppTheme.secondaryColor),
                  AdminChipItem('products', 'المنتجات', dot: AppTheme.primaryColor),
                  AdminChipItem('sales', 'المبيعات', dot: AppTheme.successColor),
                  AdminChipItem('expenses', 'المصروفات', dot: AppTheme.errorColor),
                ],
              ),
              Expanded(
                child: docs.isEmpty
                    ? adminEmpty(Icons.history_outlined, 'لا يوجد نشاط بعد',
                        _group == 'all' ? 'عند حدوث أول عملية ستظهر هنا' : 'لا يوجد نشاط في هذا التصنيف')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(0, AdminSpace.xs, 0, AdminSpace.lg),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AdminSpace.sm),
                        itemBuilder: (context, i) {
                          final d = docs[i].data();
                          final action = d['action'] as String? ?? '';
                          final desc = d['description'] as String? ?? '';
                          final color = _colorFor(action);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AdminSpace.md),
                            child: AdminCard(
                              padding: const EdgeInsets.all(AdminSpace.md),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AdminIconTile(icon: _iconFor(action), color: color, size: 42),
                                  const SizedBox(width: AdminSpace.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _labelFor(action),
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                        ),
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(desc,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12.5)),
                                        ],
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            if ((d['userId'] as String?)?.isNotEmpty ?? false)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('المستخدم: ',
                                                      style: TextStyle(
                                                          color: AdminColors.textMuted(context), fontSize: 10.5)),
                                                  CopyableId(id: d['userId'] as String),
                                                ],
                                              ),
                                            CopyableId(id: docs[i].id),
                                            Text(
                                              AdminFmt.dateTime(d['createdAt']),
                                              style: TextStyle(color: AdminColors.textMuted(context), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconFor(String action) {
    if (action.contains('approved')) return Icons.verified_outlined;
    if (action.contains('rejected')) return Icons.cancel_outlined;
    if (action.contains('sale')) return Icons.point_of_sale_outlined;
    if (action.contains('expense')) return Icons.money_off_outlined;
    if (action.contains('product')) return Icons.inventory_2_outlined;
    if (action.contains('shop') || action.contains('store')) return Icons.storefront_outlined;
    if (action.contains('subscription')) return Icons.workspace_premium_outlined;
    return Icons.history_outlined;
  }

  Color _colorFor(String action) {
    if (action.contains('approved')) return AdminColors.success;
    if (action.contains('rejected')) return AdminColors.error;
    if (action.contains('sale')) return AppTheme.primaryDark;
    if (action.contains('expense')) return AdminColors.error;
    if (action.contains('product')) return AppTheme.primaryColor;
    if (action.contains('shop') || action.contains('store')) return AppTheme.secondaryColor;
    if (action.contains('subscription')) return AppTheme.primaryColor;
    return Colors.blueGrey;
  }

  String _labelFor(String action) {
    if (action == 'subscription_approved') return 'تمت الموافقة على اشتراك';
    if (action == 'subscription_rejected') return 'تم رفض اشتراك';
    if (action.isEmpty) return 'نشاط';
    return action;
  }
}
