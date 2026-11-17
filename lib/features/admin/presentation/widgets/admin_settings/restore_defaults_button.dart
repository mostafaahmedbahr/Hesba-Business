import 'package:flutter/material.dart';

/// زر «استعادة الإعدادات الافتراضية» أسفل الفورم.
class RestoreDefaultsButton extends StatelessWidget {
  const RestoreDefaultsButton({
    super.key,
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.restart_alt_rounded, size: 18),
        label: const Text(
          'استعادة الإعدادات الافتراضية',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
