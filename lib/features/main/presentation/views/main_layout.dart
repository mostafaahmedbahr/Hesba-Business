import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
