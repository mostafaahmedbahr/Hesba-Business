import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/notification_service.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../notifications/data/repos/notification_repo.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import 'home_view.dart';
import 'more_view.dart';
import 'products_view.dart';
import 'reports_view.dart';
import 'sales_view.dart';
import '../widgets/modern_bottom_nav.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomeView(),
    ProductsView(),
    SalesView(),
    ReportsView(),
    MoreView(),
  ];

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationCubit>().ensureReminderScheduled(
            title: 'notifReminderPushTitle'.tr(),
            body: 'notifReminderPushBody'.tr(),
          );
      // Register/refresh the device FCM token at every launch so push
      // messages actually arrive (requesting permission is a no-op once granted).
      NotificationService().setupFcm();
    });
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
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: ModernBottomNav(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}
