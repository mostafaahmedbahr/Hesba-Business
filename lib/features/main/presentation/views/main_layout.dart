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
import 'more_view.dart';
import 'reports_view.dart';
import 'sales_view.dart';
import '../widgets/modern_bottom_nav.dart';
import '../../../products/presentation/views/products_view.dart';
import '../../../returns/presentation/views/returns_view.dart';
import '../../../expenses/presentation/views/expenses_view.dart';

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
    if (widget.initialTab != null) _currentIndex = widget.initialTab!;
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DashboardCubit(repo: sl())..init()),
        BlocProvider(create: (_) => NotificationCubit(repo: sl<NotificationRepo>())),
        BlocProvider(create: (_) => ActivityCubit(repo: sl<ActivityRepo>())),
      ],
      child: _MainShell(currentIndex: _currentIndex, onTabSelected: _onTabSelected),
    );
  }
}

class _MainShell extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  const _MainShell({required this.currentIndex, required this.onTabSelected});

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
    final pages = <Widget>[
      HomeView(onNavigateTab: widget.onTabSelected),
      const ProductsView(),
      const SalesView(),
      const ReturnsView(),
      const ReportsView(),
      const ExpensesView(),
      const MoreView(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: AnimatedSwitcher(
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
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
      ),
    );
  }
}
