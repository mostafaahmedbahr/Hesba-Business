
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';

class SubscriptionsView extends StatelessWidget {
  const SubscriptionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getSubscriptionsPage(startAfter: startAfter),
      )..firstPage(),
      child: const _SubsBody(),
    );
  }
}

class _SubsBody extends StatelessWidget {
  const _SubsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminListCubit, AdminListState>(
      builder: (context, state) {
        if (state.loading && state.docs.isEmpty) return const Center(child: CircularProgressIndicator());
        if (state.error != null && state.docs.isEmpty) return Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)));
        if (state.docs.isEmpty) return const Center(child: Text('لا توجد اشتراكات'));
        return ListView.separated(
          itemCount: state.docs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final d = state.docs[i].data();
            return ListTile(
              title: Text(d['plan'] as String? ?? '-'),
              subtitle: Text('userId: ${d['userId'] ?? ''}'),
              trailing: _StatusBadge(status: d['status'] as String? ?? ''),
            );
          },
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => Colors.green,
      'trial' => Colors.orange,
      'expired' => Colors.red,
      'pending' => Colors.blueGrey,
      'rejected' => Colors.redAccent,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
