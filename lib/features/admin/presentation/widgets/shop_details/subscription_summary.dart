import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/widgets/dialogs.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/subscription/data/models/subscription_model.dart';
import 'package:hesba/core/services/app_logger.dart';

/// ملخص الاشتراك في تبويب «نظرة عامة» + زر إيقاف/تفعيل المحل.
class ShopSubscriptionSummary extends StatefulWidget {
  const ShopSubscriptionSummary({super.key, required this.ownerId});
  final String ownerId;

  @override
  State<ShopSubscriptionSummary> createState() => _ShopSubscriptionSummaryState();
}

class _ShopSubscriptionSummaryState extends State<ShopSubscriptionSummary> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _future;
  bool _toggling = false;

  String get ownerId => widget.ownerId;

  @override
  void initState() {
    super.initState();
    _future = sl<AdminRepo>().getUserSubscription(ownerId);
  }

  void _reload() {
    setState(() {
      _future = sl<AdminRepo>().getUserSubscription(ownerId);
    });
  }

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
      future: _future,
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
        final suspended = (sub['suspended'] as bool?) ?? false;
        final model = SubscriptionModel.fromJson(sub);
        final working = model.canModifyData;
        final lockReason = suspended
            ? 'موقوف من الإدارة'
            : switch (model.effectiveStatus) {
                SubscriptionStatus.pending => 'قيد المراجعة',
                SubscriptionStatus.rejected => 'مرفوض',
                _ => 'انتهت المدة',
              };
        return AdminSection(
          title: 'الاشتراك',
          icon: Icons.workspace_premium_outlined,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (suspended)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: AdminStatusBadge(label: 'موقوف', color: AppTheme.danger),
                ),
              AdminStatusBadge.status(status),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminInfoRow(icon: Icons.play_arrow_outlined, label: 'المدة', value: '${AdminFmt.dateNum(sub['startDate'])} → ${AdminFmt.dateNum(sub['endDate'])}'),
              AdminInfoRow(
                icon: working ? Icons.check_circle_rounded : Icons.lock_rounded,
                label: 'الحالة',
                value: working ? 'شغال' : 'مقفول — $lockReason',
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: _toggling
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      )
                    : suspended
                        ? OutlinedButton.icon(
                            onPressed: () => _setSuspended(false),
                            icon: const Icon(Icons.play_arrow_rounded, size: 16),
                            label: const Text('إعادة تفعيل المحل', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _setSuspended(true),
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: BorderSide(color: AppTheme.danger)),
                            icon: const Icon(Icons.block_rounded, size: 16),
                            label: const Text('إيقاف المحل', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Suspends / re-activates a shop immediately, whatever its plan state.
  /// On success the section re-fetches so the new state shows at once.
  Future<void> _setSuspended(bool suspended) async {
    final ok = await showAdminConfirm(
      context,
      title: suspended ? 'إيقاف المحل' : 'إعادة تفعيل المحل',
      message: suspended
          ? 'هيتوقف المحل فورًا (قراءة فقط) حتى لو اشتراكه شغال. متأكد؟'
          : 'هيرجع المحل يشتغل طبيعي حسب اشتراكه. متأكد؟',
      confirmLabel: suspended ? 'إيقاف' : 'تفعيل',
      danger: suspended,
    );
    if (!ok || !mounted) return;
    setState(() => _toggling = true);
    try {
      await sl<AdminRepo>()
          .setShopSuspended(userId: ownerId, suspended: suspended);
      if (!mounted) return;
      AppDialogs.showSnackBar(
          context, suspended ? 'تم إيقاف المحل' : 'تم إعادة تفعيل المحل');
      _reload();
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/admin/presentation/widgets/shop_details/subscription_summary.dart', logErr, logSt, severity: LoggingSeverity.warning);
      if (!mounted) return;
      AppDialogs.showSnackBar(context, 'تعذر تنفيذ العملية', isError: true);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }
}
