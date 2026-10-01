import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/notification_service.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../notifications/data/repos/activity_repo.dart';
import '../../../notifications/data/repos/notification_repo.dart';
import '../../../notifications/presentation/view_model/activity_cubit.dart';
import '../../../notifications/presentation/view_model/notification_cubit.dart';
import '../../../returns/presentation/views/returns_view.dart';
import '../../../sales/presentation/views/sales_view.dart';
import 'home_view.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../../../products/presentation/views/products_view.dart';
import 'reports_expenses_view.dart';

/// التابات: 0 رئيسية | 1 منتجات | 2 مبيعات | 3 تقارير+مصروفات.
/// المرتجع صفحة داخلية لوحدها (تتفتح push).
class MainLayout extends StatefulWidget {
  final int? initialTab;
  final int? initialSubTab;
  const MainLayout({super.key, this.initialTab, this.initialSubTab});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  int _reportsSubTab = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      _currentIndex = widget.initialTab!.clamp(0, 3);
      if (widget.initialSubTab != null && _currentIndex == 3) {
        _reportsSubTab = widget.initialSubTab!.clamp(0, 1);
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index.clamp(0, 3));
  }

  /// يفتح المرتجع كصفحة مستقلة.
  void _openReturns() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReturnsView()),
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
        setState(() {
          _currentIndex = 3;
          _reportsSubTab = 1;
        });
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
        BlocProvider(create: (_) => ActivityCubit(repo: sl<ActivityRepo>())),
      ],
      child: _MainShell(
        currentIndex: _currentIndex,
        reportsSubTab: _reportsSubTab,
        onTabSelected: _onTabSelected,
        onOpenReturns: _openReturns,
        onHomeNavigate: _onHomeNavigate,
      ),
    );
  }
}

class _MainShell extends StatefulWidget {
  final int currentIndex;
  final int reportsSubTab;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onOpenReturns;
  final void Function(int) onHomeNavigate;
  const _MainShell({
    required this.currentIndex,
    required this.reportsSubTab,
    required this.onTabSelected,
    required this.onOpenReturns,
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
      drawer: AppDrawer(onOpenReturns: widget.onOpenReturns),
      body: Builder(
        builder: (drawerContext) {
          final pages = <Widget>[
            HomeView(onNavigateTab: widget.onHomeNavigate, onOpenDrawer: () => Scaffold.of(drawerContext).openDrawer()),
            const ProductsView(),
            const SalesView(),
            ReportsExpensesView(initialTab: widget.reportsSubTab),
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
              key: ValueKey('${widget.currentIndex}_${widget.reportsSubTab}'),
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
