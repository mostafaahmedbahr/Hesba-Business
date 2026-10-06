import 'dart:ui' as ui;

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
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
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
    _NavItem('الرئيسية', 'نظرة عامة على النظام', Icons.dashboard_outlined, Icons.dashboard),
    _NavItem('المحلات', 'إدارة المحلات المسجلة', Icons.storefront_outlined, Icons.storefront),
    _NavItem('الاشتراكات', 'حالات اشتراكات المحلات', Icons.workspace_premium_outlined, Icons.workspace_premium),
    _NavItem('طلبات الاشتراك', 'مراجعة طلبات الدفع', Icons.receipt_long_outlined, Icons.receipt_long),
    _NavItem('المنتجات', 'منتجات جميع المحلات', Icons.inventory_2_outlined, Icons.inventory_2),
    _NavItem('المبيعات', 'مبيعات جميع المحلات', Icons.point_of_sale_outlined, Icons.point_of_sale),
    _NavItem('المصروفات', 'مصروفات جميع المحلات', Icons.money_off_outlined, Icons.money_off),
    _NavItem('النشاطات', 'سجل عمليات النظام', Icons.history_outlined, Icons.history),
    _NavItem('الإعدادات', 'أسعار الباقات وطرق الدفع', Icons.settings_outlined, Icons.settings),
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
            appBar: _TopBar(title: _items[nav.index].label),
            drawer: wide
                ? null
                : Drawer(
                    child: SafeArea(
                      child: _Sidebar(
                        expanded: true,
                        selectedIndex: nav.index,
                        onSelect: (i) {
                          context.read<AdminNavCubit>().select(i);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
            body: wide
                ? Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: nav.collapsed ? 76 : 232,
                        decoration: BoxDecoration(
                          color: AdminColors.surface(context),
                          border: Border(left: BorderSide(color: AdminColors.border(context))),
                        ),
                        child: _Sidebar(
                          expanded: !nav.collapsed,
                          selectedIndex: nav.index,
                          onSelect: (i) => context.read<AdminNavCubit>().select(i),
                          onToggleCollapsed: context.read<AdminNavCubit>().toggleCollapsed,
                          collapsed: nav.collapsed,
                        ),
                      ),
                      Container(width: 1, color: AdminColors.border(context)),
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

// ── Top bar ────────────────────────────────────────────────

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      title: Text(title),
      actions: [
        IconButton(
          tooltip: 'بحث شامل',
          icon: const Icon(Icons.search),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const Center(child: SingleChildScrollView(child: AdminCard(child: GlobalSearchView()))),
          ),
        ),
        _PendingBell(),
        IconButton(
          tooltip: 'تسجيل الخروج',
          icon: const Icon(Icons.logout_outlined),
          onPressed: () => _confirmLogout(context),
        ),
        const SizedBox(width: AdminSpace.xs),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showAdminConfirm(
      context,
      title: 'تسجيل الخروج',
      message: 'هل أنت متأكد من تسجيل الخروج من لوحة الإدارة؟',
      confirmLabel: 'تسجيل الخروج',
      danger: true,
    );
    if (ok && context.mounted) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) context.read<AdminAuthCubit>().checkSession();
    }
  }
}

class _PendingBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: sl<AdminRepo>().watchPendingRequestsOnce(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return IconButton(
          tooltip: 'طلبات الاشتراك المعلقة',
          onPressed: () => context.read<AdminNavCubit>().select(3),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.expanded,
    required this.selectedIndex,
    required this.onSelect,
    this.onToggleCollapsed,
    this.collapsed = false,
  });

  final bool expanded;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onToggleCollapsed;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'مدير النظام';
    return Column(
      children: [
        _Logo(expanded: expanded),
        if (expanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AdminSpace.lg, vertical: AdminSpace.xs),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('القائمة الرئيسية',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AdminColors.textMuted(context), fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AdminSpace.xs),
            itemCount: AdminShell._items.length,
            itemBuilder: (context, i) {
              final item = AdminShell._items[i];
              return _NavTile(
                icon: i == selectedIndex ? item.activeIcon : item.icon,
                label: item.label,
                hint: item.hint,
                selected: i == selectedIndex,
                expanded: expanded,
                onTap: () => onSelect(i),
              );
            },
          ),
        ),
        if (onToggleCollapsed != null)
          _NavTile(
            icon: collapsed ? Icons.menu_open_outlined : Icons.menu_outlined,
            label: collapsed ? '' : 'طي القائمة',
            hint: 'طي / فتح القائمة',
            selected: false,
            expanded: expanded,
            onTap: onToggleCollapsed,
          ),
        const Divider(height: 1),
        _ProfileFooter(expanded: expanded, email: email),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AdminSpace.md, AdminSpace.lg, AdminSpace.md, AdminSpace.sm),
      child: Row(
        mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: AppTheme.cardShadow(context),
            ),
            child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 24),
          ),
          if (expanded) ...[
            const SizedBox(width: AdminSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('حسبة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.1)),
                  Text('لوحة الإدارة',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AdminColors.textSecondary(context), fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AdminSpace.sm, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AdminRadius.tile),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: expanded ? AdminSpace.md : 0, vertical: AdminSpace.md),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AdminRadius.tile),
          ),
          child: Row(
            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              if (selected && expanded)
                Container(
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(left: AdminSpace.sm),
                  decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(3)),
                ),
              Icon(icon, size: 21, color: selected ? AppTheme.primaryColor : AdminColors.textSecondary(context)),
              if (expanded) ...[
                const SizedBox(width: AdminSpace.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                      color: selected ? AppTheme.primaryColor : AdminColors.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (!expanded) return Tooltip(message: label.isEmpty ? hint : label, child: tile);
    return Tooltip(message: hint, waitDuration: const Duration(milliseconds: 500), child: tile);
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter({required this.expanded, required this.email});
  final bool expanded;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpace.sm),
      child: Container(
        padding: EdgeInsets.all(expanded ? AdminSpace.sm : 6),
        decoration: BoxDecoration(
          color: AdminColors.surfaceAlt(context),
          borderRadius: BorderRadius.circular(AdminRadius.tile),
        ),
        child: Row(
          mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primaryColor, size: 19),
            ),
            if (expanded) ...[
              const SizedBox(width: AdminSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مدير النظام', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: ui.TextDirection.ltr,
                        style: TextStyle(color: AdminColors.textMuted(context), fontSize: 10.5)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.hint, this.icon, this.activeIcon);
  final String label;
  final String hint;
  final IconData icon;
  final IconData activeIcon;
}
