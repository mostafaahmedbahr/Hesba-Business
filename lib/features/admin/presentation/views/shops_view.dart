import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ui.dart';
import 'package:hesba/core/theme/app_theme.dart';
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
        if (state.docs.isEmpty) return adminEmpty(Icons.storefront, 'لا توجد محلات');
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: state.docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = state.docs[i];
                  final data = d.data();
                  return _ShopTile(
                    data: data,
                    id: d.id,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShopDetailsView(
                          shopId: d.id,
                          ownerId: data['ownerId'] as String? ?? '',
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
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({required this.data, required this.id, required this.onTap});
  final Map<String, dynamic> data;
  final String id;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['shopImageUrl'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primarySoft,
                backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
                child: imageUrl.isEmpty
                    ? Icon(Icons.storefront, color: AppTheme.primaryColor)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            data['shopName'] as String? ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '#${id.length > 8 ? id.substring(0, 8) : id}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data['ownerName'] ?? '-'} • ${data['phone'] ?? '-'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['businessType'] as String? ?? '',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_left, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
