import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ui.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';

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
          return ListView.separated(
            itemCount: state.docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = state.docs[i].data();
              return ListTile(
                leading: const Icon(Icons.money_off),
                title: Text(d['title'] as String? ?? ''),
                subtitle: Text('${d['category'] ?? ''} • ${d['shopId'] ?? ''}'),
                trailing: Text('${d['amount'] ?? 0} ج'),
              );
            },
          );
        },
      ),
    );
  }
}
