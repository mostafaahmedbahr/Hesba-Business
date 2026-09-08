import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/notification_service.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../notifications/data/repos/notification_repo.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import 'home_view.dart';
import 'more_view.dart';
import 'reports_view.dart';
import 'sales_view.dart';
import '../widgets/modern_bottom_nav.dart';
import '../../../products/presentation/views/products_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DashboardCubit(repo: sl())..init(),
        ),
        BlocProvider(
          create: (_) => NotificationCubit(repo: sl<NotificationRepo>()),
        ),
      ],
      // _MainShell sits BELOW the providers, so its own context can safely
      // read them during initState's postFrameCallback.
      child: _MainShell(currentIndex: _currentIndex, onTabSelected: _onTabSelected),
    );
  }
}

class _MainShell extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _MainShell({
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  static const List<Widget> _pages = [
    HomeView(),
    ProductsView(),
    SalesView(),
    ReportsView(),
    MoreView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationCubit>().ensureAllRemindersScheduled();
      // Register/refresh the device FCM token at every launch so push
      // messages actually arrive (requesting permission is a no-op once granted).
      NotificationService().setupFcm();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: widget.currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
      ),
    );
  }
}
