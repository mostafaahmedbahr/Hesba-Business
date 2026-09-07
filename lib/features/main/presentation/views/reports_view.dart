import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../widgets/main_app_bar.dart';
import '../widgets/under_construction_view.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'navReports'.tr()),
      body: UnderConstructionView(
        icon: Icons.bar_chart_rounded,
        title: 'reportsTitle'.tr(),
        subtitle: 'reportsSubtitle'.tr(),
      ),
    );
  }
}
