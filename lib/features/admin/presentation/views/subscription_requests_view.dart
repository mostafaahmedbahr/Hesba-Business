import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/request_review_cubit.dart';
import 'package:hesba/features/subscription/data/models/subscription_request_model.dart';

class SubscriptionRequestsView extends StatefulWidget {
  const SubscriptionRequestsView({super.key});

  @override
  State<SubscriptionRequestsView> createState() => _SubscriptionRequestsViewState();
}

class _SubscriptionRequestsViewState extends State<SubscriptionRequestsView> {
  String _status = SubscriptionRequestModel.statusPending;
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
        fetch: (startAfter) => sl<AdminRepo>().getRequestsPage(startAfter: startAfter, status: _status == 'all' ? null : _status),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) {
            return Column(
              children: [
                AdminSearchField(controller: _searchCtrl, hint: 'ابحث بالمحل أو المالك أو الهاتف...', enabled: false),
                Expanded(child: adminSkeletonList(context)),
              ],
            );
          }
          if (state.error != null && state.docs.isEmpty) {
            return adminError(state.error!, () => context.read<AdminListCubit>().firstPage());
          }

          final ordered = _ordered(state.docs);
          final filtered = _applySearch(ordered);
          final searching = _query.isNotEmpty;
          final pendingTotal = state.docs.fold<num>(0, (acc, d) => acc + ((d.data()['amount'] as num?) ?? 0));

          return RefreshIndicator(
            onRefresh: () => context.read<AdminListCubit>().firstPage(),
            child: Column(
              children: [
                const AdminPageHeader(title: 'طلبات الاشتراك', description: 'مراجعة طلبات الدفع والموافقة عليها أو رفضها'),
                AdminSummaryHeader(
                  icon: Icons.receipt_long_outlined,
                  title: _status == SubscriptionRequestModel.statusPending ? 'طلبات معلقة' : 'طلبات الاشتراك',
                  total: state.docs.length,
                  unit: 'طلب',
                  stats: [
                    if (_status == SubscriptionRequestModel.statusPending)
                      'إجمالي المبالغ: ${AdminFmt.money(pendingTotal)}'
                    else
                      'الحالة: ${_requestStatusLabel(_status)}'
                  ],
                  loading: state.loading,
                  onRefresh: () => context.read<AdminListCubit>().firstPage(),
                ),
                AdminSearchField(
                  controller: _searchCtrl,
                  hint: 'ابحث بالمحل أو المالك أو الهاتف...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                AdminFilterChips(
                  selected: _status,
                  onSelect: (k) => setState(() => _status = k),
                  items: [
                    AdminChipItem(SubscriptionRequestModel.statusPending, 'معلقة', dot: AdminStatuses.colorOf('pending')),
                    const AdminChipItem('all', 'الكل'),
                    AdminChipItem(SubscriptionRequestModel.statusApproved, 'مقبولة', dot: AdminStatuses.colorOf('approved')),
                    AdminChipItem(SubscriptionRequestModel.statusRejected, 'مرفوضة', dot: AdminStatuses.colorOf('rejected')),
                  ],
                ),
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
                      ? adminEmpty(
                          Icons.receipt_long_outlined,
                          searching
                              ? 'لا توجد نتائج مطابقة لبحثك'
                              : _status == SubscriptionRequestModel.statusPending
                                  ? 'لا توجد طلبات معلقة'
                                  : 'لا توجد طلبات بهذه الحالة',
                          searching ? null : 'عند وصول طلب جديد سيظهر هنا')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(0, AdminSpace.xs, 0, AdminSpace.lg),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AdminSpace.sm),
                          itemBuilder: (context, i) {
                            final d = filtered[i];
                            final request = SubscriptionRequestModel.fromJson(d.id, d.data());
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AdminSpace.md),
                              child: _RequestCard(request: request),
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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _ordered(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final list = [...docs];
    list.sort((a, b) {
      final da = AdminFmt.toDate(a.data()['createdAt']);
      final db = AdminFmt.toDate(b.data()['createdAt']);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applySearch(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return docs;
    return docs.where((d) {
      final data = d.data();
      final haystack = [data['shopName'], data['ownerName'], data['phone'], data['userId'], d.id]
          .whereType<String>()
          .join(' ')
          .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }
}

String _requestStatusLabel(String s) {
  return switch (s) {
    'pending' => 'معلق',
    'approved' => 'مقبول',
    'rejected' => 'مرفوض',
    'all' => 'الكل',
    _ => s,
  };
}

// ── Card ────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final SubscriptionRequestModel request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final statusColor = AdminStatuses.colorOf(r.status == 'approved' ? 'approved' : r.status);
    return AdminCard(
      padding: const EdgeInsets.all(AdminSpace.md),
      onTap: () => _openDetails(context, r),
      child: Row(
        children: [
          if (r.paymentProofUrl.isNotEmpty)
            AdminThumbnail(url: r.paymentProofUrl, size: 52, icon: Icons.receipt_long_outlined)
          else
            const AdminIconTile(icon: Icons.receipt_long_outlined, color: AppTheme.primaryColor, size: 52),
          const SizedBox(width: AdminSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(r.shopName,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                    const SizedBox(width: 6),
                    AdminStatusBadge(label: _requestStatusLabel(r.status), color: statusColor),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${r.ownerName} • ${r.phone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AdminRadius.pill)),
                      child: Text(_planLabel(r.plan.id),
                          style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Text(AdminFmt.money(r.amount),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 6),
                    Text(AdminFmt.dateNum(r.createdAt),
                        style: TextStyle(fontSize: 11, color: AdminColors.textMuted(context))),
                  ],
                ),
                const SizedBox(height: 2),
                CopyableId(id: r.requestId),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: AdminColors.textMuted(context), size: 22),
        ],
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, SubscriptionRequestModel request) async {
    await RequestDetailsDialog.show(context, request);
    if (context.mounted) context.read<AdminListCubit>().firstPage();
  }
}

String _planLabel(String id) {
  return switch (id) {
    'monthly' => 'شهري',
    'threeMonths' => '3 شهور',
    'sixMonths' => '6 شهور',
    'yearly' => 'سنوي',
    _ => id,
  };
}

// ── Details dialog (receipt + details) ──────────────────
// Public + reusable: the global search opens the same dialog directly.

class RequestDetailsDialog extends StatefulWidget {
  const RequestDetailsDialog({super.key, required this.request});
  final SubscriptionRequestModel request;

  static Future<void> show(BuildContext context, SubscriptionRequestModel request) {
    return showDialog(context: context, builder: (_) => RequestDetailsDialog(request: request));
  }

  @override
  State<RequestDetailsDialog> createState() => _RequestDetailsDialogState();
}

class _RequestDetailsDialogState extends State<RequestDetailsDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return BlocProvider(
      create: (_) => RequestReviewCubit(repo: sl<AdminRepo>()),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.dialog)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpace.xl),
            child: BlocConsumer<RequestReviewCubit, RequestReviewState>(
              listener: (context, state) {
                if (state is ReviewDone) {
                  AppToast.success(context, state.approved ? 'تمت الموافقة على الطلب' : 'تم رفض الطلب');
                  Navigator.of(context).pop();
                } else if (state is ReviewError) {
                  AppToast.error(context, state.message);
                }
              },
              builder: (context, state) {
                final loading = state is ReviewLoading;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('مراجعة طلب الاشتراك',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                Text('${r.shopName} — ${r.ownerName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AdminColors.textSecondary(context))),
                              ],
                            ),
                          ),
                          AdminStatusBadge(
                              label: _requestStatusLabel(r.status),
                              color: AdminStatuses.colorOf(r.status == 'approved' ? 'approved' : r.status)),
                          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
                        ],
                      ),
                      const SizedBox(height: AdminSpace.md),
                      LayoutBuilder(builder: (context, constraints) {
                        final twoPane = constraints.maxWidth >= 640;
                        final receipt = _ReceiptPane(url: r.paymentProofUrl);
                        final details = _DetailsPane(request: r);
                        if (!twoPane) return Column(children: [receipt, const SizedBox(height: AdminSpace.md), details]);
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: receipt),
                              const SizedBox(width: AdminSpace.md),
                              Expanded(child: details),
                            ],
                          ),
                        );
                      }),
                      if (r.isPending) ...[
                        const SizedBox(height: AdminSpace.md),
                        TextField(
                          controller: _reason,
                          decoration: const InputDecoration(labelText: 'سبب الرفض (يظهر للمالك عند الرفض)'),
                          maxLines: 2,
                        ),
                      ],
                      if (!r.isPending && (r.adminNote?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: AdminSpace.md),
                        AdminInfoRow(icon: Icons.note_outlined, label: 'ملاحظة الإدارة', value: r.adminNote!),
                      ],
                      const SizedBox(height: AdminSpace.xl),
                      Row(
                        children: [
                          if (r.isPending) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: loading ? null : () => context.read<RequestReviewCubit>().approve(r),
                                child: loading
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('موافقة'),
                              ),
                            ),
                            const SizedBox(width: AdminSpace.sm),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: AdminColors.error),
                                onPressed:
                                    loading ? null : () => context.read<RequestReviewCubit>().reject(r, _reason.text.trim()),
                                child: const Text('رفض'),
                              ),
                            ),
                            const SizedBox(width: AdminSpace.sm),
                          ],
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('إغلاق'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptPane extends StatelessWidget {
  const _ReceiptPane({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AdminIconTile(icon: Icons.receipt_long_outlined, color: AppTheme.primaryColor, size: 34, iconSize: 18),
              const SizedBox(width: AdminSpace.sm),
              Text('إيصال الدفع', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              if (url.isNotEmpty)
                Text('اضغط للتكبير', style: TextStyle(fontSize: 11, color: AdminColors.textMuted(context))),
            ],
          ),
          const SizedBox(height: AdminSpace.md),
          if (url.isEmpty)
            adminEmpty(Icons.image_not_supported_outlined, 'لا يوجد إيصال مرفق')
          else
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(AdminRadius.card),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => _ReceiptFullScreen(url: url)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AdminRadius.card),
                  child: Image.network(url, height: 300, fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => adminEmpty(Icons.broken_image_outlined, 'تعذر تحميل الإيصال')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReceiptFullScreen extends StatelessWidget {
  const _ReceiptFullScreen({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إيصال الدفع')),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(child: Image.network(url)),
      ),
    );
  }
}

class _DetailsPane extends StatelessWidget {
  const _DetailsPane({required this.request});
  final SubscriptionRequestModel request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات الطلب', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AdminSpace.md),
          CopyableId(id: r.requestId, full: true, label: 'معرف الطلب'),
          const Divider(height: 20),
          if (r.userId.isNotEmpty) ...[
            CopyableId(id: r.userId, full: true, label: 'معرف المستخدم'),
            const Divider(height: 20),
          ],
          AdminInfoRow(icon: Icons.storefront_outlined, label: 'المحل', value: r.shopName),
          const Divider(height: 14),
          AdminInfoRow(icon: Icons.person_outline, label: 'المالك', value: r.ownerName),
          const Divider(height: 14),
          AdminInfoRow(icon: Icons.phone_outlined, label: 'الهاتف', value: r.phone),
          const Divider(height: 14),
          AdminInfoRow(
              icon: Icons.workspace_premium_outlined,
              label: 'الباقة',
              value: '${_planLabel(r.plan.id)} • ${r.plan.days} يوم'),
          const Divider(height: 14),
          AdminInfoRow(icon: Icons.payments_outlined, label: 'المبلغ', value: AdminFmt.money(r.amount)),
          const Divider(height: 14),
          AdminInfoRow(icon: Icons.wallet_outlined, label: 'طريقة الدفع', value: _payLabel(r.paymentMethod)),
          const Divider(height: 14),
          AdminInfoRow(icon: Icons.calendar_month_outlined, label: 'تاريخ الطلب', value: AdminFmt.dateTime(r.createdAt)),
          if (r.reviewedAt != null) ...[
            const Divider(height: 14),
            AdminInfoRow(icon: Icons.rate_review_outlined, label: 'تاريخ المراجعة', value: AdminFmt.dateTime(r.reviewedAt)),
          ],
        ],
      ),
    );
  }

  String _payLabel(String id) {
    return switch (id) {
      'instapay' => 'انستاباي',
      'vodafone_cash' => 'فودافون كاش',
      'etisalat_cash' => 'اتصالات كاش',
      '' => '-',
      _ => id,
    };
  }
}
