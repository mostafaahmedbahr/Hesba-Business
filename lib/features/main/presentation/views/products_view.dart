import 'package:flutter/material.dart';

import '../widgets/main_app_bar.dart';
import '../widgets/under_construction_view.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: 'المنتجات'),
      body: const UnderConstructionView(
        icon: Icons.category_rounded,
        title: 'المنتجات',
        subtitle: 'إدارة المنتجات قريباً\nأضف، عدّل، واحذف منتجاتك من هنا',
      ),
    );
  }
}
