import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/notification_service.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../notifications/data/repos/activity_repo.dart';
import '../../../notifications/data/repos/notification_repo.dart';
import '../../../notifications/presentation/view_model/notification_cubit.dart';
import '../../../expenses/presentation/views/expenses_view.dart';
import '../../../returns/presentation/views/returns_view.dart';
import '../../../sales/presentation/views/sales_view.dart';
import 'home_view.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../../../products/presentation/views/products_view.dart';
import '../../../reports/presentation/views/reports_view.dart';

/// التابات: 0 رئيسية | 1 منتجات | 2 مبيعات | 3 تقارير.
/// المرتجع والمصروفات صفحات داخلية لوحدها (تتفتح push).
class MainLayout extends StatefulWidget {
  final int? initialTab;
  const MainLayout({super.key, this.initialTab});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      _currentIndex = widget.initialTab!.clamp(0, 3);
    }
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index.clamp(0, 3));
  }

  /// تنقل الـ Drawer (تابات فقط).
  void _onDrawerNavigate(int index) {
    setState(() => _currentIndex = index.clamp(0, 3));
  }

  /// يفتح المرتجع كصفحة مستقلة.
  void _openReturns() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReturnsView()),
    );
  }

  /// يفتح المصروفات كصفحة مستقلة.
  void _openExpenses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpensesView()),
    );
  }

  /// تنقل أزرار الرئيسية (1 منتجات | 2 مبيعات | 3 مرتجع | 5 مصروفات).
  void _onHomeNavigate(int oldIndex) {
    switch (oldIndex) {
      case 1:
        _onTabSelected(1);
        break;
      case 2:
        _onTabSelected(2);
        break;
      case 3:
        _openReturns();
        break;
      case 5:
        _openExpenses();
        break;
      default:
        _onTabSelected(oldIndex.clamp(0, 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DashboardCubit(repo: sl())..init()),
        BlocProvider(
          create: (_) => NotificationCubit(
            repo: sl<NotificationRepo>(),
            activityRepo: sl<ActivityRepo>(),
          ),
        ),
      ],
      child: _MainShell(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
        onDrawerNavigate: _onDrawerNavigate,
        onOpenReturns: _openReturns,
        onOpenExpenses: _openExpenses,
        onHomeNavigate: _onHomeNavigate,
      ),
    );
  }
}

class _MainShell extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<int> onDrawerNavigate;
  final VoidCallback onOpenReturns;
  final VoidCallback onOpenExpenses;
  final void Function(int) onHomeNavigate;
  const _MainShell({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onDrawerNavigate,
    required this.onOpenReturns,
    required this.onOpenExpenses,
    required this.onHomeNavigate,
  });

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationCubit>().loadReminders();
      NotificationService().setupFcm();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      drawer: AppDrawer(
        onNavigateTab: widget.onDrawerNavigate,
        onOpenReturns: widget.onOpenReturns,
        onOpenExpenses: widget.onOpenExpenses,
      ),
      body: Builder(
        builder: (drawerContext) {
          final pages = <Widget>[
            HomeView(onNavigateTab: widget.onHomeNavigate, onOpenDrawer: () => Scaffold.of(drawerContext).openDrawer()),
            const ProductsView(),
            const SalesView(),
            const ReportsView(),
          ];
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(widget.currentIndex),
              child: IndexedStack(index: widget.currentIndex, children: pages),
            ),
          );
        },
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
      ),
    );
  }
}
