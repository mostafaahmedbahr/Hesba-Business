import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/widgets/loading_widget.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:easy_localization/easy_localization.dart';

/// تاب الاشتراك: بيانات الاشتراك الحالية للمالك المرتبط بالمحل.
class ShopSubscriptionTab extends StatelessWidget {
  const ShopSubscriptionTab({super.key, required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    if (ownerId.isEmpty) {
      return adminEmpty(Icons.workspace_premium_outlined, 'لا يوجد مالك مرتبط بهذا المحل'.tr());
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: sl<AdminRepo>().getUserSubscription(ownerId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingWidget();
        final sub = snap.data?.data();
        if (sub == null || sub.isEmpty) {
          return adminEmpty(Icons.workspace_premium_outlined, 'لا يوجد اشتراك لهذا المحل'.tr());
        }
        final status = (sub['status'] as String?) ?? '-';
        final plan = _planName(sub['plan']);
        final isTrial = (sub['isTrial'] as bool?) ?? false;
        return ListView(
          padding: const EdgeInsets.fromLTRB(AdminSpace.md, AdminSpace.xs, AdminSpace.md, AdminSpace.lg),
          children: [
            AdminSection(
              title: 'حالة الاشتراك'.tr(),
              icon: Icons.workspace_premium_outlined,
              trailing: AdminStatusBadge.status(status),
              child: Column(
                children: [
                  AdminInfoRow(icon: Icons.workspace_premium_outlined, label: 'الباقة'.tr(), value: plan),
                  const Divider(height: 14),
                  AdminInfoRow(icon: Icons.timelapse_outlined, label: 'تجريبي'.tr(), value: isTrial ? 'نعم'.tr() : 'لا'.tr()),
                  const Divider(height: 14),
                  AdminInfoRow(icon: Icons.play_arrow_outlined, label: 'تاريخ البدء'.tr(), value: AdminFmt.date(sub['startDate'])),
                  const Divider(height: 14),
                  AdminInfoRow(icon: Icons.stop_outlined, label: 'تاريخ الانتهاء'.tr(), value: AdminFmt.date(sub['endDate'])),
                  const Divider(height: 14),
                  AdminInfoRow(icon: Icons.update_outlined, label: 'آخر تحديث'.tr(), value: AdminFmt.date(sub['updatedAt'])),
                  if ((sub['lastRequestId'] as String?)?.isNotEmpty ?? false) ...[
                    const Divider(height: 14),
                    AdminInfoRow(icon: Icons.receipt_long_outlined, label: 'آخر طلب'.tr(), value: sub['lastRequestId'].toString(), copyable: true),
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
