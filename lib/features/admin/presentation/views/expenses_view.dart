import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ui.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});
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
            decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFFE11D48), size: 20),
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

class ExpensesView extends StatelessWidget {
  const ExpensesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getExpensesPage(startAfter: startAfter),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) return adminSkeletonList(context);
          if (state.error != null && state.docs.isEmpty) return adminError(state.error!, () => context.read<AdminListCubit>().firstPage());
          if (state.docs.isEmpty) return adminEmpty(Icons.money_off, 'لا توجد مصروفات');
          final total = state.docs.fold<num>(0, (sum, d) => sum + ((d.data()['amount'] as num?)?.toInt() ?? 0));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.money_off,
                        label: 'عدد المصروفات',
                        value: '${state.docs.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.payments,
                        label: 'الإجمالي',
                        value: '${total.toInt()} ج',
                      ),
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
                    final createdAt = d['createdAt'];
                    String date = d['date']?.toString() ?? '';
                    if (date.isEmpty) {
                      try {
                        date = (createdAt as dynamic).toDate().toString().substring(0, 10);
                      } catch (_) {}
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {},
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
                                decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.money_off, color: Color(0xFFE11D48), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d['title'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('${d['category'] ?? '-'}${date.isNotEmpty ? ' • $date' : ''}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                child: Text('${d['amount'] ?? 0} ج', style: const TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
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
