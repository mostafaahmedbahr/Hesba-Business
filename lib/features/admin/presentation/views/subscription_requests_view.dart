
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ui.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/request_review_cubit.dart';
import 'package:hesba/features/subscription/data/models/subscription_request_model.dart';

class SubscriptionRequestsView extends StatelessWidget {
  const SubscriptionRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getRequestsPage(startAfter: startAfter, status: 'pending'),
      )..firstPage(),
      child: const _RequestsBody(),
    );
  }
}

class _RequestsBody extends StatelessWidget {
  const _RequestsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminListCubit, AdminListState>(
      builder: (context, state) {
        if (state.loading && state.docs.isEmpty) return adminSkeletonList(context);
        if (state.error != null && state.docs.isEmpty) return adminError(state.error!, () => context.read<AdminListCubit>().firstPage());
        if (state.docs.isEmpty) return adminEmpty(Icons.receipt_long, 'لا توجد طلبات معلقة');
        // ترتيب في الذاكرة حسب createdAt (الأحدث أولاً) لأن الاستعلام
        // المفلتر لا يستخدم orderBy في السيرفر (تجنباً لطلب composite index).
        final ordered = [...state.docs]..sort((a, b) => _tsCmp(b.data()['createdAt'], a.data()['createdAt']));
        return ListView.separated(
          itemCount: ordered.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final d = ordered[i].data();
            final request = SubscriptionRequestModel.fromJson(ordered[i].id, d);
            return ListTile(
              title: Text(request.shopName),
              subtitle: Text('${request.ownerName} • ${request.phone} • ${request.plan.id} • ${request.amount}ج'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => _openDetails(context, request),
            );
          },
        );
      },
    );
  }

  Future<void> _openDetails(BuildContext context, SubscriptionRequestModel request) async {
    await showDialog(
      context: context,
      builder: (context) => _RequestDialog(request: request),
    );
    if (context.mounted) context.read<AdminListCubit>().firstPage();
  }
}

int _tsCmp(dynamic a, dynamic b) {
  DateTime? toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  final da = toDate(a);
  final db = toDate(b);
  if (da == null && db == null) return 0;
  if (da == null) return 1;
  if (db == null) return -1;
  return da.compareTo(db);
}

class _RequestDialog extends StatefulWidget {
  const _RequestDialog({required this.request});
  final SubscriptionRequestModel request;

  @override
  State<_RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<_RequestDialog> {
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocConsumer<RequestReviewCubit, RequestReviewState>(
              listener: (context, state) {
                if (state is ReviewDone) {
                  AppToast.success(context, state.approved ? 'تمت الموافقة' : 'تم الرفض');
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
                      Text('تفاصيل الطلب', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Text('${r.shopName} - ${r.ownerName}'),
                      Text('الهاتف: ${r.phone}'),
                      Text('الباقة: ${r.plan.id} • المبلغ: ${r.amount} ج'),
                      Text('طريقة الدفع: ${r.paymentMethod}'),
                      const SizedBox(height: 12),
                      if (r.paymentProofUrl.isNotEmpty) ...[
                        const Text('إيصال الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(title: const Text('إيصال الدفع')),
                                body: InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 4,
                                  child: Center(child: Image.network(r.paymentProofUrl)),
                                ),
                              ),
                            ),
                          ),
                          child: Image.network(r.paymentProofUrl, height: 260, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(controller: _reason, decoration: const InputDecoration(labelText: 'سبب الرفض (اختياري)')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: loading ? null : () => context.read<RequestReviewCubit>().approve(r),
                            child: const Text('موافقة'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: loading ? null : () => context.read<RequestReviewCubit>().reject(r, _reason.text.trim()),
                            child: const Text('رفض'),
                          ),
                          const Spacer(),
                          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق')),
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
