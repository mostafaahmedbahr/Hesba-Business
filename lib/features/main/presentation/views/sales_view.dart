import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../widgets/main_app_bar.dart';
import '../widgets/under_construction_view.dart';

class SalesView extends StatelessWidget {
  const SalesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'navSales'.tr()),
      body: UnderConstructionView(
        icon: Icons.receipt_long_rounded,
        title: 'salesTitle'.tr(),
        subtitle: 'salesSubtitle'.tr(),
      ),
    );
  }
}
