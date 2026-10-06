import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';

import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_auth_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_nav_cubit.dart';
import 'package:hesba/features/admin/presentation/views/activity_view.dart';
import 'package:hesba/features/admin/presentation/views/admin_settings_view.dart';
import 'package:hesba/features/admin/presentation/views/dashboard_view.dart';
import 'package:hesba/features/admin/presentation/views/expenses_view.dart';
import 'package:hesba/features/admin/presentation/views/global_search_view.dart';
import 'package:hesba/features/admin/presentation/views/products_view.dart';
import 'package:hesba/features/admin/presentation/views/sales_view.dart';
import 'package:hesba/features/admin/presentation/views/shops_view.dart';
import 'package:hesba/features/admin/presentation/views/subscription_requests_view.dart';
import 'package:hesba/features/admin/presentation/views/subscriptions_view.dart';

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
          final wide = MediaQuery.of(context).size.width >= 760;
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              centerTitle: false,
              title: Text(_items[nav.index].label),
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
            drawer: wide
                ? null
                : Drawer(
                    child: SafeArea(
                      child: _NavList(
                        expanded: true,
                        selectedIndex: nav.index,
                        onSelect: (i) {
                          context.read<AdminNavCubit>().select(i);
                          Navigator.of(context).pop();
                        },
                        onToggleCollapsed: null,
                      ),
                    ),
                  ),
            body: wide
                ? Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: nav.collapsed ? 64 : 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border(
                            left: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                          ),
                        ),
                        child: _NavList(
                          expanded: !nav.collapsed,
                          selectedIndex: nav.index,
                          onSelect: (i) => context.read<AdminNavCubit>().select(i),
                          onToggleCollapsed: context.read<AdminNavCubit>().toggleCollapsed,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: _page(nav.index)),
                    ],
                  )
                : _page(nav.index),
          );
        },
      ),
    );
  }
}

class _NavList extends StatelessWidget {
  const _NavList({
    required this.expanded,
    required this.selectedIndex,
    required this.onSelect,
    required this.onToggleCollapsed,
  });

  final bool expanded;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onToggleCollapsed;

  Widget _navTile({
    required IconData icon,
    required String label,
    required bool selected,
    required bool expanded,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: selected ? AppTheme.primaryColor : Colors.black54),
              if (expanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? AppTheme.primaryColor : Colors.black87,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: AdminShell._items.length + (onToggleCollapsed != null ? 1 : 0),
      itemBuilder: (context, i) {
        if (onToggleCollapsed != null && i == AdminShell._items.length) {
          return _navTile(
            icon: Icons.menu_open,
            label: 'طي',
            selected: false,
            expanded: expanded,
            onTap: onToggleCollapsed,
          );
        }
        final item = AdminShell._items[i];
        return _navTile(
          icon: item.icon,
          label: item.label,
          selected: i == selectedIndex,
          expanded: expanded,
          onTap: () => onSelect(i),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}
