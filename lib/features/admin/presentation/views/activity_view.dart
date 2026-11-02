import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';

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
      'shops' => action.contains('shop') || action.contains('store'),
      'products' => action.contains('product'),
      'sales' => action.contains('sale'),
      'expenses' => action.contains('expense'),
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: sl<AdminRepo>().watchActivityLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              const AdminPageHeader(
                title: 'سجل النشاطات',
                description: 'متابعة كل إجراءات الأدمن داخل لوحة التحكم',
              ),
              Expanded(child: adminSkeletonList(context)),
            ],
          );
        }
        if (snapshot.hasError) {
          return adminError('تعذر تحميل سجل النشاطات', () => setState(() {}));
        }

        final all = snapshot.data?.docs ?? [];
        final docs = all
            .where((d) => _matches((d.data()['action'] as String?) ?? ''))
            .toList();

        final groups = _groupByDate(docs);

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Column(
            children: [
              const AdminPageHeader(
                title: 'سجل النشاطات',
                description: 'سجل زمني يوضح ما تم تنفيذه، ومن قام به، وأين',
              ),
              AdminSummaryHeader(
                icon: Icons.timeline_outlined,
                title: 'إجمالي النشاطات المسجلة',
                total: all.length,
                unit: 'عملية',
                stats: [
                  if (_group != 'all')
                    'يتم عرض ${docs.length} عملية من أصل ${all.length}'
                  else
                    'آخر ١٠٠ عملية مرتبة بالأحدث أولاً'
                ],
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
                    ? adminEmpty(
                  Icons.history_outlined,
                  'لا يوجد نشاط لعرضه',
                  _group == 'all'
                      ? 'عند قيام الأدمن بأي إجراء سيظهر هنا مباشرةً'
                      : 'لا توجد نشاطات ضمن هذا التصنيف حالياً',
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AdminSpace.md, AdminSpace.xs, AdminSpace.md, AdminSpace.lg),
                  itemCount: groups.length,
                  itemBuilder: (context, gIndex) {
                    final group = groups[gIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            0,
                            gIndex == 0 ? 0 : AdminSpace.lg,
                            0,
                            AdminSpace.sm,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                group.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Divider(
                                  color: AdminColors.border(context),
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (var i = 0; i < group.items.length; i++) ...[
                          _ActivityCard(doc: group.items[i]),
                          if (i != group.items.length - 1)
                            const SizedBox(height: AdminSpace.sm),
                        ],
                      ],
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

  List<_DateGroup> _groupByDate(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final groups = <_DateGroup>[];
    String? currentKey;

    for (final doc in docs) {
      final data = doc.data();
      final dt = _toDate(data['createdAt']);
      final key = _dateKey(dt);
      final title = _dateTitle(dt);

      if (currentKey != key) {
        groups.add(_DateGroup(title: title, items: [doc], key: key));
        currentKey = key;
      } else {
        groups.last.items.add(doc);
      }
    }
    return groups;
  }

  DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  String _dateKey(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'yesterday';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _dateTitle(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'اليوم';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'أمس';
    }
    return AdminFmt.dateNum(dt);
  }
}

class _DateGroup {
  _DateGroup({required this.title, required this.items, required this.key});
  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> items;
  final String key;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final action = (data['action'] as String? ?? '').trim();
    final desc = (data['description'] as String? ?? '').trim();
    final extra = data['extra'] is Map ? Map<String, dynamic>.from(data['extra']) : const <String, dynamic>{};
    final shopName = (extra['shopName'] as String?)?.trim();
    final userId = (extra['userId'] as String? ?? data['userId'] as String? ?? '').trim();
    final color = _colorFor(action);
    final icon = _iconFor(action);
    final title = _titleFor(action, desc, shopName);
    final details = _detailsFor(action, desc, shopName);
    final time = _time(data['createdAt']);

    return AdminCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AdminRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AdminSpace.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AdminRadius.tile),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: AdminSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AdminSpace.sm),
                              Text(
                                time,
                                style: TextStyle(
                                  color: AdminColors.textMuted(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (details.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              details,
                              style: TextStyle(
                                color: AdminColors.textSecondary(context),
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ],
                          if (shopName != null && shopName.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AdminColors.surfaceAlt(context),
                                borderRadius: BorderRadius.circular(AdminRadius.pill),
                                border: Border.all(color: AdminColors.border(context)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.storefront_outlined,
                                    size: 14,
                                    color: AdminColors.textSecondary(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      shopName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (userId.isNotEmpty)
                                _MetaItem(
                                  icon: Icons.admin_panel_settings_outlined,
                                  label: 'تم بواسطة الأدمن',
                                  copyValue: userId,
                                ),
                              _MetaItem(
                                icon: Icons.fingerprint_outlined,
                                label: 'معرّف السجل',
                                copyValue: doc.id,
                              ),
                              _MetaItem(
                                icon: Icons.calendar_today_outlined,
                                label: AdminFmt.dateTime(data['createdAt']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(dynamic v) {
    final dt = _toDate(v);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'م' : 'ص';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:$m $p';
  }

  DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  String _titleFor(String action, String desc, String? shopName) {
    if (action == 'subscription_approved') {
      return shopName != null && shopName.isNotEmpty
          ? 'تمت الموافقة على طلب اشتراك المحل'
          : 'تمت الموافقة على طلب اشتراك';
    }
    if (action == 'subscription_rejected') {
      return shopName != null && shopName.isNotEmpty
          ? 'تم رفض طلب اشتراك المحل'
          : 'تم رفض طلب اشتراك';
    }
    if (action == 'subscription_suspended') {
      return shopName != null && shopName.isNotEmpty
          ? 'تم تعليق المحل مؤقتاً'
          : 'تم تعليق الاشتراك / المحل';
    }
    if (action == 'subscription_unsuspended') {
      return shopName != null && shopName.isNotEmpty
          ? 'تم إعادة تفعيل المحل'
          : 'تم إعادة تفعيل الاشتراك';
    }
    if (action == 'subscription_request_created') return 'تم إرسال طلب اشتراك جديد';
    if (action == 'shop_created' || action.contains('shop_create')) return 'تم إنشاء محل جديد';
    if (action == 'product_added') return 'تم إضافة منتج جديد';
    if (action == 'sale_created') return 'تم تسجيل عملية بيع';
    if (action == 'expense_created') return 'تم إضافة مصروف جديد';

    if (action.isEmpty) return 'إجراء إداري';
    return action.replaceAll('_', ' ');
  }

  String _detailsFor(String action, String desc, String? shopName) {
    if (action == 'subscription_approved') {
      if (desc.contains(' for ')) {
        final parts = desc.split(' for ');
        if (parts.length == 2) {
          return 'تم تفعيل الاشتراك للباقة: ${parts[1].replaceAll(shopName ?? '', '').trim().isEmpty ? parts[1] : parts[1].replaceAll(shopName ?? '', '').trim()}';
        }
      }
      return desc.isNotEmpty ? desc : 'تم تحويل حالة الطلب إلى "مُوافق عليه" وتفعيل الاشتراك للمحل.';
    }
    if (action == 'subscription_rejected') {
      if (desc.contains(':')) {
        final parts = desc.split(':');
        if (parts.length >= 2 && parts.last.trim().isNotEmpty) {
          return 'سبب الرفض: ${parts.last.trim()}';
        }
      }
      return desc.isNotEmpty ? desc : 'تم رفض طلب الاشتراك مع إبقاء السجل للمراجعة.';
    }
    if (action == 'subscription_suspended') {
      return 'تم حجب صلاحية المحل مؤقتاً حتى يتم إعادة التفعيل من لوحة الإدارة.';
    }
    if (action == 'subscription_unsuspended') {
      return 'عاد المحل للعمل بشكل طبيعي بعد إزالة التعليق.';
    }
    return desc;
  }

  IconData _iconFor(String action) {
    if (action.contains('approved')) return Icons.verified_rounded;
    if (action.contains('rejected')) return Icons.cancel_rounded;
    if (action.contains('suspended') && !action.contains('unsuspended')) return Icons.block_rounded;
    if (action.contains('unsuspended')) return Icons.check_circle_rounded;
    if (action.contains('sale')) return Icons.point_of_sale_rounded;
    if (action.contains('expense')) return Icons.receipt_long_rounded;
    if (action.contains('product')) return Icons.inventory_2_rounded;
    if (action.contains('shop') || action.contains('store')) return Icons.storefront_rounded;
    if (action.contains('subscription')) return Icons.workspace_premium_rounded;
    return Icons.history_rounded;
  }

  Color _colorFor(String action) {
    if (action.contains('approved')) return AdminColors.success;
    if (action.contains('rejected')) return AdminColors.error;
    if (action.contains('suspended') && !action.contains('unsuspended')) return AdminColors.warning;
    if (action.contains('unsuspended')) return AdminColors.success;
    if (action.contains('sale')) return AppTheme.primaryDark;
    if (action.contains('expense')) return AdminColors.error;
    if (action.contains('product')) return AppTheme.primaryColor;
    if (action.contains('shop') || action.contains('store')) return AppTheme.secondaryColor;
    if (action.contains('subscription')) return AppTheme.primaryColor;
    return Colors.blueGrey;
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label, this.copyValue});
  final IconData icon;
  final String label;
  final String? copyValue;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AdminColors.textMuted(context)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: AdminColors.textMuted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (copyValue != null && copyValue!.isNotEmpty) ...[
          const SizedBox(width: 4),
          Icon(Icons.copy_rounded, size: 12, color: AdminColors.textMuted(context)),
        ],
      ],
    );

    if (copyValue == null || copyValue!.isEmpty) return child;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        Clipboard.setData(ClipboardData(text: copyValue!));
        AppToast.success(context, 'تم نسخ المعرّف');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: child,
      ),
    );
  }
}