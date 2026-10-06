import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/admin/presentation/views/product_details_view.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getProductsPage(startAfter: startAfter),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.error != null && state.docs.isEmpty) return Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)));
          if (state.docs.isEmpty) return const Center(child: Text('لا توجد منتجات'));
          return ListView.separated(
            itemCount: state.docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = state.docs[i].data();
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (d['imageUrl'] as String? ?? '').isEmpty ? null : NetworkImage(d['imageUrl'] as String),
                  child: (d['imageUrl'] as String? ?? '').isEmpty ? const Icon(Icons.inventory_2) : null,
                ),
                title: Text(d['name'] as String? ?? ''),
                subtitle: Text('${d['category'] ?? ''} • الكمية: ${d['stock'] ?? 0}'),
                trailing: Text('${d['price'] ?? 0} ج'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsView(data: d, id: state.docs[i].id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
