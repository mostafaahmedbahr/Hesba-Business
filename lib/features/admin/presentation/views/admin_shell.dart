import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';

import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_auth_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_nav_cubit.dart';
import 'package:hesba/features/admin/presentation/views/dashboard_view.dart';
import 'package:hesba/features/admin/presentation/views/shops_view.dart';
import 'package:hesba/features/admin/presentation/views/subscriptions_view.dart';
import 'package:hesba/features/admin/presentation/views/subscription_requests_view.dart';
import 'package:hesba/features/admin/presentation/views/products_view.dart';
import 'package:hesba/features/admin/presentation/views/sales_view.dart';
import 'package:hesba/features/admin/presentation/views/expenses_view.dart';
import 'package:hesba/features/admin/presentation/views/activity_view.dart';
import 'package:hesba/features/admin/presentation/views/global_search_view.dart';
import 'package:hesba/features/admin/presentation/views/admin_settings_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  static const _items = [
    _NavItem('الرئيسية', Icons.dashboard_outlined),
    _NavItem('المحلات', Icons.storefront_outlined),
    _NavItem('الاشتراكات', Icons.workspace_premium_outlined),
    _NavItem('طلبات الاشتراك', Icons.receipt_long_outlined),
    _NavItem('المنتجات', Icons.inventory_2_outlined),
    _NavItem('المبيعات', Icons.point_of_sale_outlined),
    _NavItem('المصروفات', Icons.money_off_outlined),
    _NavItem('النشاطات', Icons.history_outlined),
    _NavItem('الإعدادات', Icons.settings_outlined),
  ];

  Widget _page(int index) {
    switch (index) {
      case 0:
        return BlocProvider(
          create: (_) => AdminDashboardCubit(repo: sl<AdminRepo>())..load(),
          child: const DashboardView(),
        );
      case 1:
        return const ShopsView();
      case 2:
        return const SubscriptionsView();
      case 3:
        return const SubscriptionRequestsView();
      case 4:
        return const ProductsView();
      case 5:
        return const SalesView();
      case 6:
        return const ExpensesView();
      case 7:
        return const ActivityView();
      case 8:
        return const AdminSettingsView();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminNavCubit(),
      child: BlocBuilder<AdminNavCubit, AdminNavState>(
        builder: (context, nav) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_items[nav.index].label),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => Center(
                      child: Card(child: const GlobalSearchView()),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.read<AdminNavCubit>().select(3),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) context.read<AdminAuthCubit>().checkSession();
                  },
                ),
              ],
            ),
            body: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: nav.collapsed ? 64 : 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _items.length + 1,
                    itemBuilder: (context, i) {
                      if (i == _items.length) {
                        return ListTile(
                          leading: const Icon(Icons.menu_open),
                          title: nav.collapsed ? null : const Text('إخفاء'),
                          onTap: () => context.read<AdminNavCubit>().toggleCollapsed(),
                        );
                      }
                      final item = _items[i];
                      return ListTile(
                        selected: i == nav.index,
                        leading: Icon(item.icon),
                        title: nav.collapsed ? null : Text(item.label),
                        onTap: () => context.read<AdminNavCubit>().select(i),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _page(nav.index)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}
