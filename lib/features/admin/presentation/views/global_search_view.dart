import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/features/admin/presentation/cubit/global_search_cubit.dart';

class GlobalSearchView extends StatelessWidget {
  const GlobalSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GlobalSearchCubit(),
      child: Builder(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'ابحث عن محل أو منتج أو طلب',
                    ),
                    onChanged: (v) => context.read<GlobalSearchCubit>().search(v),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<GlobalSearchCubit, GlobalSearchState>(
                    builder: (context, state) {
                      if (state is SearchLoading) {
                        return const LinearProgressIndicator();
                      }
                      if (state is SearchResults) {
                        if (state.hits.isEmpty) {
                          return const Padding(padding: EdgeInsets.all(12), child: Text('لا نتائج'));
                        }
                        return SizedBox(
                          height: 320,
                          child: ListView.separated(
                            itemCount: state.hits.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final hit = state.hits[i];
                              return ListTile(
                                leading: Icon(_iconFor(hit.kind)),
                                title: Text(hit.title),
                                subtitle: Text(hit.kind),
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox(height: 1);
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
        'محل' => Icons.storefront,
        'منتج' => Icons.inventory_2_outlined,
        _ => Icons.receipt_long,
      };
}
