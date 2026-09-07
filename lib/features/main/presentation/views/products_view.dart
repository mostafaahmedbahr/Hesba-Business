import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../widgets/main_app_bar.dart';
import '../widgets/under_construction_view.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'navProducts'.tr()),
      body: UnderConstructionView(
        icon: Icons.category_rounded,
        title: 'productsTitle'.tr(),
        subtitle: 'productsSubtitle'.tr(),
      ),
    );
  }
}
