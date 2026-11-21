import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/main/presentation/views/main_layout.dart' show BackAction, decideBackAction;
import '../utils/toast.dart';

/// يحمي شاشات ما قبل/بعد الـ layout من الخروج بضغطة رجوع واحدة.
/// الضغطة الأولى تعرض رسالة، والتانية خلال ٢ ثانية تخرج من التطبيق.
class ExitGuard extends StatefulWidget {
  const ExitGuard({super.key, required this.child});

  final Widget child;

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  DateTime? _lastBackPress;

  void _handleBack() {
    final now = DateTime.now();
    final action = decideBackAction(
      currentIndex: 0,
      lastBackPress: _lastBackPress,
      now: now,
    );
    switch (action) {
      case BackAction.warn:
        _lastBackPress = now;
        AppToast.info(context, 'pressBackAgainToExit'.tr());
      case BackAction.exit:
        SystemNavigator.pop();
      case BackAction.goHome:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: widget.child,
    );
  }
}
