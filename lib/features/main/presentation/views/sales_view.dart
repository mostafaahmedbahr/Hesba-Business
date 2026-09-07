import 'package:flutter/material.dart';

import '../widgets/main_app_bar.dart';
import '../widgets/under_construction_view.dart';

class SalesView extends StatelessWidget {
  const SalesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: 'المبيعات'),
      body: const UnderConstructionView(
        icon: Icons.receipt_long_rounded,
        title: 'المبيعات',
        subtitle: 'سجّل مبيعاتك وتابع الفواتير\nمن هذه الصفحة قريباً',
      ),
    );
  }
}
