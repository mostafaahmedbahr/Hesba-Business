import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/subscription/data/models/subscription_plan.dart';

class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  String _status = 'all';
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(_status),
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getSubscriptionsPage(
          startAfter: startAfter,
          status: _status == 'all' ? null : _status,
        ),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) {
            return Column(
              children: [
                AdminSearchField(controller: _searchCtrl, hint: 'ابحث برقم المستخدم أو الباقة...', enabled: false),
                Expanded(child: adminSkeletonList(context)),
              ],
            );
          }
          if (state.error != null && state.docs.isEmpty) {
            return adminError(state.error!, () => context.read<AdminListCubit>().firstPage());
          }
          if (state.docs.isEmpty && _query.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => context.read<AdminListCubit>().firstPage(),
              child: ListView(
                children: [
                  const AdminPageHeader(title: 'الاشتراكات', description: 'حالات اشتراكات جميع المحلات في النظام'),
                  AdminSummaryHeader(
                      icon: Icons.workspace_premium_outlined,
                      title: 'إجمالي الاشتراكات',
                      total: 0,
                      unit: 'اشتراك',
                      loading: false,
                      onRefresh: () => context.read<AdminListCubit>().firstPage()),
                  AdminSearchField(controller: _searchCtrl, hint: 'ابحث برقم المستخدم أو الباقة...', enabled: false),
                  _statusChips(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: adminEmpty(Icons.workspace_premium_outlined, 'لا توجد اشتراكات',
                        _status == 'all' ? 'عند بدء أول اشتراك سيظهر هنا' : 'لا توجد اشتراكات بهذه الحالة'),
                  ),
                ],
              ),
            );
          }

          final filtered = _applySearch(_ordered(state.docs));
          final searching = _query.isNotEmpty;

          return RefreshIndicator(
            onRefresh: () => context.read<AdminListCubit>().firstPage(),
            child: Column(
              children: [
                const AdminPageHeader(title: 'الاشتراكات', description: 'حالات اشتراكات جميع المحلات في النظام'),
                _summary(context, state),
                AdminSearchField(
                  controller: _searchCtrl,
                  hint: 'ابحث برقم المستخدم أو الباقة...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                _statusChips(countFor: (s) => _countFor(state.docs, s)),
                if (searching)
                  AdminResultCount(
                    count: filtered.length,
                    clearLabel: 'مسح البحث',
                    onClear: () => setState(() {
                      _query = '';
                      _searchCtrl.clear();
                    }),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? adminEmpty(Icons.search_off_outlined, 'لا توجد نتائج مطابقة لبحثك')
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            if (wide) {
                              return GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(AdminSpace.lg, AdminSpace.xs, AdminSpace.lg, AdminSpace.lg),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: constraints.maxWidth >= 1100 ? 3 : 2,
                                  crossAxisSpacing: AdminSpace.md,
                                  mainAxisSpacing: AdminSpace.md,
                                  mainAxisExtent: 172,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) => _SubCard(
                                  doc: filtered[i],
                                  onTap: () => _openDetails(context, filtered[i]),
                                ),
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(0, AdminSpace.xs, 0, AdminSpace.lg),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: AdminSpace.sm),
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AdminSpace.md),
                                child: _SubCard(
                                  doc: filtered[i],
                                  onTap: () => _openDetails(context, filtered[i]),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (state.hasMore)
                  AdminLoadMore(
                    loading: state.loading,
                    label: 'تحميل المزيد (${state.docs.length} معروض)',
                    onLoad: () => context.read<AdminListCubit>().nextPage(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _countFor(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String s) =>
      s == 'all' ? docs.length : docs.where((d) => (d.data()['status'] as String?) == s).length;

  Widget _summary(BuildContext context, AdminListState state) {
    int count(String s) => state.docs.where((d) => (d.data()['status'] as String?) == s).length;
    return AdminSummaryHeader(
      icon: Icons.workspace_premium_outlined,
      title: 'إجمالي الاشتراكات',
      total: state.docs.length,
      unit: 'اشتراك',
      stats: ['نشط ${count('active')}', 'تجريبي ${count('trial')}', 'منتهي ${count('expired')}'],
      loading: state.loading,
      onRefresh: () => context.read<AdminListCubit>().firstPage(),
    );
  }

  Widget _statusChips({int Function(String)? countFor}) {
    const items = ['all', 'active', 'trial', 'expired', 'pending', 'rejected'];
    return AdminFilterChips(
      selected: _status,
      onSelect: (k) => setState(() => _status = k),
      items: [
        for (final k in items)
          AdminChipItem(
            k,
            AdminStatuses.labelOf(k),
            count: countFor?.call(k),
            dot: k == 'all' ? null : AdminStatuses.colorOf(k),
          ),
      ],
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _ordered(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final list = [...docs];
    list.sort((a, b) {
      final da = AdminFmt.toDate(a.data()['updatedAt']);
      final db = AdminFmt.toDate(b.data()['updatedAt']);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applySearch(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final q = _query.trim();
    if (q.isEmpty) return docs;
    return docs.where((d) {
      final data = d.data();
      final haystack = [data['userId'], data['plan'], data['status'], d.id].whereType<String>().join(' ');
      return haystack.contains(q);
    }).toList();
  }

  void _openDetails(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    showAdminSheet(context, _SubDetailsSheet(data: doc.data(), docId: doc.id));
  }
}

// ── Card ────────────────────────────────────────────────

class _SubCard extends StatelessWidget {
  const _SubCard({required this.doc, required this.onTap});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final theme = Theme.of(context);

    final status = (data['status'] as String?) ?? '';
    final planId = (data['plan'] as String?) ?? '';
    final userId = (data['userId'] as String?) ?? doc.id;
    final isTrial = (data['isTrial'] as bool?) ?? (status == 'trial');
    final endDate = AdminFmt.toDate(data['endDate']);
    final startDate = AdminFmt.toDate(data['startDate']);
    final remaining = endDate?.difference(DateTime.now()).inDays;
    final statusColor = AdminStatuses.colorOf(status);
    final sub = AdminColors.textSecondary(context);

    return AdminCard(
      padding: const EdgeInsets.all(13),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminIconTile(icon: AdminStatuses.iconOf(status), color: statusColor, size: 42),
              const SizedBox(width: AdminSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_planLabel(planId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                          'user: ${AdminFmt.shortId(userId, 10)}${userId.length > 10 ? '…' : ''}',
                          style: TextStyle(fontSize: 11, color: sub, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              AdminStatusBadge.status(status),
            ],
          ),
          const SizedBox(height: AdminSpace.sm),
          Row(
            children: [
              _pill(Icons.calendar_month_outlined, AdminFmt.dateNum(startDate), context),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_back, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              _pill(Icons.event_outlined, AdminFmt.dateNum(endDate), context),
              const Spacer(),
              if (remaining != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: (remaining <= 0
                            ? AdminColors.error
                            : remaining <= 7
                                ? AdminColors.warning
                                : AdminColors.success)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AdminRadius.pill),
                  ),
                  child: Text(
                    remaining <= 0 ? 'انتهى' : 'متبقي $remaining يوم',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: remaining <= 0
                          ? AdminColors.error
                          : remaining <= 7
                              ? AdminColors.warning
                              : AdminColors.success,
                    ),
                  ),
                ),
            ],
          ),
          if (isTrial)
            Padding(
              padding: const EdgeInsets.only(top: AdminSpace.sm),
              child: Row(
                children: [
                  Icon(Icons.timelapse_outlined, size: 13, color: sub),
                  const SizedBox(width: 4),
                  Text('فترة تجريبية', style: TextStyle(fontSize: 11.5, color: sub, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('اضغط للتفاصيل', style: TextStyle(fontSize: 11, color: sub)),
                  Icon(Icons.chevron_left_rounded, size: 18, color: AdminColors.textMuted(context)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text, BuildContext context) {
    final color = AdminColors.textSecondary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AdminColors.surfaceAlt(context), borderRadius: BorderRadius.circular(AdminRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Details sheet ───────────────────────────────────────

class _SubDetailsSheet extends StatelessWidget {
  const _SubDetailsSheet({required this.data, required this.docId});
  final Map<String, dynamic> data;
  final String docId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = (data['status'] as String?) ?? '';
    final planId = (data['plan'] as String?) ?? '';
    final userId = (data['userId'] as String?) ?? docId;
    final isTrial = (data['isTrial'] as bool?) ?? false;
    final start = AdminFmt.toDate(data['startDate']);
    final end = AdminFmt.toDate(data['endDate']);
    final updated = AdminFmt.toDate(data['updatedAt']);
    final remaining = end?.difference(DateTime.now()).inDays;
    final statusColor = AdminStatuses.colorOf(status);

    SubscriptionPlan? plan;
    try {
      plan = SubscriptionPlan.fromId(planId);
    } catch (_) {
      plan = null;
    }

    double? progress;
    if (start != null && end != null && end.isAfter(start)) {
      final total = end.difference(start).inDays.clamp(1, 10000);
      final left = (remaining ?? 0).clamp(0, total);
      progress = left / total;
    }

    return AdminSheetShell(
      title: _planLabel(planId),
      subtitle: 'اشتراك ${AdminStatuses.labelOf(status)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminIconTile(icon: AdminStatuses.iconOf(status), color: statusColor, size: 48),
              const SizedBox(width: AdminSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_planLabel(planId), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    Text('${plan?.days ?? '-'} يوم • ${plan == null ? '-' : AdminFmt.money(plan.price)}',
                        style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12)),
                  ],
                ),
              ),
              AdminStatusBadge.status(status),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AdminRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AdminColors.border(context),
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              (remaining ?? 0) <= 0 ? 'انتهت المدة' : 'متبقي ${remaining ?? 0} يوم من أصل ${end!.difference(start!).inDays} يوم',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),
          CopyableId(id: userId, full: true, label: 'معرف المستخدم'),
          const Divider(height: 20),
          CopyableId(id: docId, full: true, label: 'معرف المستند'),
          const Divider(height: 20),
          AdminInfoRow(icon: Icons.timelapse_outlined, label: 'تجريبي', value: isTrial ? 'نعم' : 'لا'),
          const Divider(height: 14),
          AdminInfoRow(icon: Icons.play_arrow_outlined, label: 'البدء', value: AdminFmt.date(start)),
          const Divider(height: 14),
          AdminInfoRow(icon: Icons.stop_outlined, label: 'الانتهاء', value: AdminFmt.date(end)),
          const Divider(height: 14),
          AdminInfoRow(icon: Icons.update_outlined, label: 'آخر تحديث', value: AdminFmt.date(updated)),
        ],
      ),
    );
  }
}

String _planLabel(String id) {
  return switch (id) {
    'monthly' => 'شهري',
    'threeMonths' => '3 شهور',
    'sixMonths' => '6 شهور',
    'yearly' => 'سنوي',
    '' => '-',
    _ => id,
  };
}
