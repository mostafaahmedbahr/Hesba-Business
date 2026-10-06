import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/admin/presentation/views/shop_details_view.dart';

class ShopsView extends StatelessWidget {
  const ShopsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getShopsPage(startAfter: startAfter),
      )..firstPage(),
      child: const _ShopsBody(),
    );
  }
}

class _ShopsBody extends StatelessWidget {
  const _ShopsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminListCubit, AdminListState>(
      builder: (context, state) {
        if (state.loading && state.docs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.docs.isEmpty) {
          return Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)));
        }
        if (state.docs.isEmpty) return const Center(child: Text('لا توجد محلات'));
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: state.docs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final d = state.docs[i].data();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (d['shopImageUrl'] as String? ?? '').isEmpty
                          ? null
                          : NetworkImage(d['shopImageUrl'] as String),
                      child: (d['shopImageUrl'] as String? ?? '').isEmpty ? const Icon(Icons.storefront) : null,
                    ),
                    title: Text(d['shopName'] as String? ?? ''),
                    subtitle: Text('${d['ownerName'] ?? ''} • ${d['phone'] ?? ''}'),
                    trailing: Text(d['businessType'] as String? ?? ''),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShopDetailsView(
                          shopId: state.docs[i].id,
                          ownerId: d['ownerId'] as String? ?? '',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (state.hasMore)
              Padding(
                padding: const EdgeInsets.all(8),
                child: OutlinedButton(
                  onPressed: state.loading ? null : () => context.read<AdminListCubit>().nextPage(),
                  child: state.loading ? const CircularProgressIndicator() : const Text('تحميل المزيد'),
                ),
              ),
          ],
        );
      },
    );
  }
}
