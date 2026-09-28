import 'package:flutter/material.dart';

import 'notifications_view.dart';

/// اسم قديم للشاشة (موجود عشان أي import قديم مايتكسرش).
@Deprecated('استخدم NotificationsView بدلاً منها')
class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) => const NotificationsView();
}
