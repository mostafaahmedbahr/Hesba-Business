import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/services/user_role_service.dart';
import 'package:hesba/core/theme/app_theme.dart';

import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_auth_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_nav_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_settings_cubit.dart';
import 'package:hesba/features/admin/presentation/views/activity_view.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:hesba/features/admin/presentation/views/admin_settings_view.dart';
import 'package:hesba/features/admin/presentation/views/dashboard_view.dart';
import 'package:hesba/features/admin/presentation/views/expenses_view.dart';
import 'package:hesba/features/admin/presentation/views/feedback_view.dart';
import 'package:hesba/features/admin/presentation/views/global_search_view.dart';
import 'package:hesba/features/admin/presentation/views/products_view.dart';
import 'package:hesba/features/admin/presentation/views/sales_view.dart';
import 'package:hesba/features/admin/presentation/views/shops_view.dart';
import 'package:hesba/features/admin/presentation/views/subscription_requests_view.dart';
import 'package:hesba/features/admin/presentation/views/subscriptions_view.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  static final items= [
    _NavItem('الرئيسية'.tr(), 'نظرة عامة على النظام'.tr(), Icons.dashboard_outlined, Icons.dashboard),
    _NavItem('المحلات'.tr(), 'إدارة المحلات المسجلة'.tr(), Icons.storefront_outlined, Icons.storefront),
    _NavItem('الاشتراكات'.tr(), 'حالات اشتراكات المحلات'.tr(), Icons.workspace_premium_outlined, Icons.workspace_premium),
    _NavItem('طلبات الاشتراك'.tr(), 'مراجعة طلبات الدفع'.tr(), Icons.receipt_long_outlined, Icons.receipt_long),
    _NavItem('المنتجات'.tr(), 'منتجات جميع المحلات'.tr(), Icons.inventory_2_outlined, Icons.inventory_2),
    _NavItem('المبيعات'.tr(), 'مبيعات جميع المحلات'.tr(), Icons.point_of_sale_outlined, Icons.point_of_sale),
    _NavItem('المصروفات'.tr(), 'مصروفات جميع المحلات'.tr(), Icons.money_off_outlined, Icons.money_off),
    _NavItem('النشاطات'.tr(), 'سجل عمليات النظام'.tr(), Icons.history_outlined, Icons.history),
    _NavItem('الملاحظات'.tr(), 'شكاوى واقتراحات المستخدمين'.tr(), Icons.feedback_outlined, Icons.feedback),
    _NavItem('الإعدادات'.tr(), 'أسعار الباقات وطرق الدفع'.tr(), Icons.settings_outlined, Icons.settings),
  ];

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  /// Page widgets are created ONCE on first visit and kept alive in an
  /// IndexedStack. Switching tabs no longer rebuilds the Cubit / re-reads
  /// Firestore — pull-to-refresh (and the 60s return refresh below) are the
  /// only triggers for new reads.
  final List<Widget?> _pages = List<Widget?>.filled(10, null);
  final List<GlobalKey> _keys =
      List<GlobalKey>.generate(10, (i) => GlobalKey(debugLabel: 'admin-page-$i'));
  final Map<int, DateTime> _lastVisit = {};

  @override
  void initState() {
    super.initState();
    _page(0); // build the first page once; others are created on first visit
    _lastVisit[0] = DateTime.now();
  }

  /// Refresh a returning tab only when its data is stale (>60s). Fresh data
  /// from a recent visit is reused as-is — zero reads on quick tab switches.
  void _maybeRefreshOnReturn(int index) {
    final last = _lastVisit[index];
    if (last == null || DateTime.now().difference(last) < const Duration(seconds: 60)) {
      return;
    }
    final ctx = _keys[index].currentContext;
    if (ctx == null) return;
    try {
      ctx.read<AdminDashboardCubit>().load();
      return;
    } catch (_) {}
    try {
      ctx.read<AdminSettingsCubit>().load();
      return;
    } catch (_) {}
    try {
      ctx.read<AdminListCubit>().firstPage();
    } catch (_) {}
  }

  void _selectTab(BuildContext context, int index) {
    // `context` here must come from inside BlocBuilder (below BlocProvider),
    // otherwise context.read<AdminNavCubit>() throws ProviderNotFoundError.
    final nav = context.read<AdminNavCubit>();
    if (index == nav.state.index) return;
    _maybeRefreshOnReturn(index);
    _page(index); // create on first visit only
    _lastVisit[index] = DateTime.now();
    nav.select(index);
  }

  Widget _page(int index) {
    final existing = _pages[index];
    if (existing != null) return existing;
    final page = _buildPage(index);
    _pages[index] = page;
    return page;
  }

  Widget _stack(int currentIndex) => IndexedStack(
        index: currentIndex,
        children: List.generate(10, (i) => _pages[i] ?? const SizedBox.shrink()),
      );

  Widget _buildPage(int index) {
    final key = _keys[index];
    switch (index) {
      case 0:
        return BlocProvider(
          key: key,
          create: (_) => AdminDashboardCubit(repo: sl<AdminRepo>())..load(),
          child: const DashboardView(),
        );
      case 1:
        return ShopsView(key: key);
      case 2:
        return SubscriptionsView(key: key);
      case 3:
        return SubscriptionRequestsView(key: key);
      case 4:
        return ProductsView(key: key);
      case 5:
        return SalesView(key: key);
      case 6:
        return ExpensesView(key: key);
      case 7:
        return ActivityView(key: key);
      case 8:
        return FeedbackView(key: key);
      case 9:
        return AdminSettingsView(key: key);
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
            appBar: _TopBar(title: AdminShell.items[nav.index].label),
            drawer: wide
                ? null
                : Drawer(
                    child: SafeArea(
                      child: _Sidebar(
                        expanded: true,
                        selectedIndex: nav.index,
                        onSelect: (i) {
                          _selectTab(context, i);
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
                          onSelect: (i) => _selectTab(context, i),
                          onToggleCollapsed: context.read<AdminNavCubit>().toggleCollapsed,
                          collapsed: nav.collapsed,
                        ),
                      ),
                      Container(width: 1, color: AdminColors.border(context)),
                      Expanded(child: _stack(nav.index)),
                    ],
                  )
                : _stack(nav.index),
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
          tooltip: 'بحث شامل'.tr(),
          icon: const Icon(Icons.search),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const Center(child: SingleChildScrollView(child: AdminCard(child: GlobalSearchView()))),
          ),
        ),
        _PendingBell(),
        IconButton(
          tooltip: 'تسجيل الخروج'.tr(),
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
      title: 'تسجيل الخروج'.tr(),
      message: 'هل أنت متأكد من تسجيل الخروج من لوحة الإدارة؟'.tr(),
      confirmLabel: 'تسجيل الخروج'.tr(),
      danger: true,
    );
    if (ok && context.mounted) {
      await sl<AdminRepo>().signOutAdmin();
      // Keep the shared role cache in sync with the sign-out.
      sl<UserRoleService>().clear();
      if (context.mounted) context.read<AdminAuthCubit>().checkSession();
    }
  }
}

class _PendingBell extends StatefulWidget {
  const _PendingBell();

  @override
  State<_PendingBell> createState() => _PendingBellState();
}

class _PendingBellState extends State<_PendingBell> {
  // Create the live listener ONCE. Previously it was built inline in build(),
  // so every nav/sidebar rebuild tore down and re-attached a Firestore listener.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _pendingStream =
      sl<AdminRepo>().watchPendingRequestsOnce();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pendingStream,
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return IconButton(
          tooltip: 'طلبات الاشتراك المعلقة'.tr(),
          onPressed: () => context.read<AdminNavCubit>().select(3),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count >= 100 ? '99+' : '$count'),
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
    final email = sl<AdminRepo>().currentAdminEmail() ?? 'مدير النظام'.tr();
    return Column(
      children: [
        _Logo(expanded: expanded),
        if (expanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AdminSpace.lg, vertical: AdminSpace.xs),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('القائمة الرئيسية'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AdminColors.textMuted(context), fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AdminSpace.xs),
            itemCount: AdminShell.items.length,
            itemBuilder: (context, i) {
              final item = AdminShell.items[i];
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
            label: collapsed ? '' : 'طي القائمة'.tr(),
            hint: 'طي / فتح القائمة'.tr(),
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
                  Text('حسبة'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.1)),
                  Text('لوحة الإدارة'.tr(),
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
                    Text('مدير النظام'.tr(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
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
