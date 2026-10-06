import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ui.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF22C55E), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SalesView extends StatelessWidget {
  const SalesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getSalesPage(startAfter: startAfter),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) return adminSkeletonList(context);
          if (state.error != null && state.docs.isEmpty) return adminError(state.error!, () => context.read<AdminListCubit>().firstPage());
          if (state.docs.isEmpty) return adminEmpty(Icons.point_of_sale, 'لا توجد مبيعات');
          final revenue = state.docs.fold<num>(0, (sum, d) => sum + ((d.data()['total'] as num?)?.toInt() ?? 0));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(icon: Icons.point_of_sale, label: 'عدد المبيعات', value: '${state.docs.length}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(icon: Icons.payments, label: 'الإجمالي', value: '${revenue.toInt()} ج'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: state.docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = state.docs[i].data();
                    String date = '';
                    final c = d['createdAt'];
                    try {
                      date = (c as dynamic)?.toDate().toString().substring(0, 10) ?? '';
                    } catch (_) {}
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.point_of_sale, color: Color(0xFF22C55E), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${d['total'] ?? 0} ج', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('${d['shopId'] ?? '-'}${date.isNotEmpty ? ' • $date' : ''}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  if (d['paymentMethod'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('${d['paymentMethod']}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('#${state.docs[i].id.length > 8 ? state.docs[i].id.substring(0, 8) : state.docs[i].id}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (state.hasMore)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton(
                    onPressed: state.loading ? null : () => context.read<AdminListCubit>().nextPage(),
                    child: state.loading ? const CircularProgressIndicator() : const Text('تحميل المزيد'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
