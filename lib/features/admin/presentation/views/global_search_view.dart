import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/cubit/global_search_cubit.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/presentation/views/product_details_view.dart';
import 'package:hesba/features/admin/presentation/views/shop_details_view.dart';
import 'package:hesba/features/admin/presentation/views/subscription_requests_view.dart';
import 'package:hesba/features/subscription/data/models/subscription_request_model.dart';

class GlobalSearchView extends StatelessWidget {
  const GlobalSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GlobalSearchCubit(),
      child: Builder(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(AdminSpace.xl),
            child: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('بحث شامل',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: 'إغلاق'),
                    ],
                  ),
                  const SizedBox(height: AdminSpace.xs),
                  Text('ابحث عن محل أو منتج أو طلب اشتراك',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AdminColors.textSecondary(context))),
                  const SizedBox(height: AdminSpace.md),
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'ابحث عن محل أو منتج أو طلب...',
                    ),
                    onChanged: (v) => context.read<GlobalSearchCubit>().search(v),
                  ),
                  const SizedBox(height: AdminSpace.md),
                  BlocBuilder<GlobalSearchCubit, GlobalSearchState>(
                    builder: (context, state) {
                      if (state is SearchLoading) {
                        return const LinearProgressIndicator(minHeight: 4);
                      }
                      if (state is SearchResults) {
                        if (state.hits.isEmpty) {
                          return adminEmpty(Icons.search_off_outlined, 'لا توجد نتائج');
                        }
                        return SizedBox(
                          height: 320,
                          child: ListView.separated(
                            itemCount: state.hits.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AdminSpace.sm),
                            itemBuilder: (context, i) {
                              final hit = state.hits[i];
                              return AdminCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AdminSpace.md, vertical: AdminSpace.sm),
                                onTap: () => _openHit(context, hit),
                                child: Row(
                                  children: [
                                    AdminIconTile(
                                        icon: _iconFor(hit.kind), color: _colorFor(hit.kind), size: 40),
                                    const SizedBox(width: AdminSpace.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(hit.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              AdminStatusBadge(label: hit.kind, color: _colorFor(hit.kind)),
                                              const SizedBox(width: 6),
                                              CopyableId(id: hit.id),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_left_rounded, color: AdminColors.textMuted(context), size: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AdminSpace.lg),
                          child: Text('اكتب كلمة للبحث في المحلات والمنتجات والطلبات',
                              style: TextStyle(color: AdminColors.textMuted(context), fontSize: 12.5)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String kind) => switch (kind) {
        'محل' => Icons.storefront_outlined,
        'منتج' => Icons.inventory_2_outlined,
        _ => Icons.receipt_long_outlined,
      };

  Color _colorFor(String kind) => switch (kind) {
        'محل' => AppTheme.primaryColor,
        'منتج' => AppTheme.secondaryColor,
        _ => AppTheme.successColor,
      };

  Future<void> _openHit(BuildContext context, SearchHit hit) async {
    // Details open ON TOP of the search dialog (no pop first):
    // going back returns to the results, and the context stays valid.
    final messenger = ScaffoldMessenger.of(context);
    try {
      final kind = hit.kind.trim();
      if (kind == 'محل') {
        final snap = await FirebaseFirestore.instance.collection('shops').doc(hit.id).get();
        if (!context.mounted) return;
        if (!snap.exists) {
          messenger.showSnackBar(
            const SnackBar(content: Text('المحل غير موجود'), behavior: SnackBarBehavior.floating),
          );
          return;
        }
        final data = snap.data() ?? {};
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShopDetailsView(shopId: hit.id, ownerId: data['ownerId'] as String? ?? ''),
          ),
        );
      } else if (kind == 'منتج') {
        final snap = await FirebaseFirestore.instance.collection('products').doc(hit.id).get();
        if (!context.mounted) return;
        final data = snap.data();
        if (data == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('المنتج غير موجود'), behavior: SnackBarBehavior.floating),
          );
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailsView(data: data, id: hit.id)),
        );
      } else {
        // طلب اشتراك: افتح حوار مراجعة الطلب نفسه بدل الذهاب للقائمة.
        final snap =
            await FirebaseFirestore.instance.collection('subscription_requests').doc(hit.id).get();
        if (!context.mounted) return;
        final data = snap.data();
        if (data == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('الطلب غير موجود'), behavior: SnackBarBehavior.floating),
          );
          return;
        }
        final request = SubscriptionRequestModel.fromJson(hit.id, data);
        await RequestDetailsDialog.show(context, request);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('تعذر فتح التفاصيل: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}
