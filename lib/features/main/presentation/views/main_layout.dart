import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/notification_service.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../notifications/data/repos/activity_repo.dart';
import '../../../notifications/data/repos/notification_repo.dart';
import '../../../notifications/presentation/cubit/activity_cubit.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import 'home_view.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../../../products/presentation/views/products_view.dart';
import 'sales_returns_view.dart';
import 'reports_expenses_view.dart';

class MainLayout extends StatefulWidget {
  final int? initialTab;
  final int? initialSubTab;
  const MainLayout({super.key, this.initialTab, this.initialSubTab});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  int _salesSubTab = 0;
  int _reportsSubTab = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      _currentIndex = widget.initialTab!.clamp(0, 3);
      if (widget.initialSubTab != null) {
        if (_currentIndex == 2) _salesSubTab = widget.initialSubTab!.clamp(0, 1);
        if (_currentIndex == 3) _reportsSubTab = widget.initialSubTab!.clamp(0, 1);
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index.clamp(0, 3));
  }

  void _onDrawerNavigate(int bottomIndex, {int? subTab}) {
    setState(() {
      _currentIndex = bottomIndex.clamp(0, 3);
      if (subTab != null) {
        if (bottomIndex == 2) _salesSubTab = subTab.clamp(0, 1);
        if (bottomIndex == 3) _reportsSubTab = subTab.clamp(0, 1);
      }
    });
  }

  /// Called from Home QuickActions / Recent cards
  /// Maps old indices (1=Products, 2=Sales, 3=Returns, 5=Expenses) to new 4-tab model
  void _onHomeNavigate(int oldIndex) {
    switch (oldIndex) {
      case 1:
        _onTabSelected(1);
        break;
      case 2:
        setState(() { _currentIndex = 2; _salesSubTab = 0; });
        break;
      case 3:
        setState(() { _currentIndex = 2; _salesSubTab = 1; });
        break;
      case 5:
        setState(() { _currentIndex = 3; _reportsSubTab = 1; });
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
        BlocProvider(create: (_) => NotificationCubit(repo: sl<NotificationRepo>())),
        BlocProvider(create: (_) => ActivityCubit(repo: sl<ActivityRepo>())),
      ],
      child: _MainShell(
        currentIndex: _currentIndex,
        salesSubTab: _salesSubTab,
        reportsSubTab: _reportsSubTab,
        onTabSelected: _onTabSelected,
        onDrawerNavigate: _onDrawerNavigate,
        onHomeNavigate: _onHomeNavigate,
      ),
    );
  }
}

class _MainShell extends StatefulWidget {
  final int currentIndex;
  final int salesSubTab;
  final int reportsSubTab;
  final ValueChanged<int> onTabSelected;
  final void Function(int, {int? subTab}) onDrawerNavigate;
  final void Function(int) onHomeNavigate;
  const _MainShell({
    required this.currentIndex,
    required this.salesSubTab,
    required this.reportsSubTab,
    required this.onTabSelected,
    required this.onDrawerNavigate,
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
      context.read<NotificationCubit>().ensureAllRemindersScheduled();
      NotificationService().setupFcm();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      drawer: AppDrawer(onNavigateBottom: widget.onDrawerNavigate),
      body: Builder(
        builder: (drawerContext) {
          // Provide correct Scaffold context for HomeView drawer button
          final pagesWithDrawerContext = <Widget>[
            HomeView(onNavigateTab: widget.onHomeNavigate, onOpenDrawer: () => Scaffold.of(drawerContext).openDrawer()),
            const ProductsView(),
            SalesReturnsView(initialTab: widget.salesSubTab),
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
              key: ValueKey('${widget.currentIndex}_${widget.salesSubTab}_${widget.reportsSubTab}'),
              child: IndexedStack(index: widget.currentIndex, children: pagesWithDrawerContext),
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
