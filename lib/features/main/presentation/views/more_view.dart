import 'package:flutter/material.dart';

import '../widgets/main_app_bar.dart';
import '../widgets/under_construction_view.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: 'المزيد'),
      body: const UnderConstructionView(
        icon: Icons.grid_view_rounded,
        title: 'المزيد',
        subtitle: 'الإعدادات والخدمات الإضافية\nستظهر هنا قريباً',
      ),
    );
  }
}
