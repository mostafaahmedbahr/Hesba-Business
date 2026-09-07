import 'package:flutter/material.dart';

import '../widgets/main_app_bar.dart';
import '../widgets/under_construction_view.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: 'التقارير'),
      body: const UnderConstructionView(
        icon: Icons.bar_chart_rounded,
        title: 'التقارير',
        subtitle: 'تحليلات وأرقام مبيعاتك\nستظهر هنا قريباً',
      ),
    );
  }
}
