import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/theme/app_theme.dart';

class AppDialogs {
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '',
    String cancelText = '',
  }) {
    final confirm = confirmText.isEmpty ? 'dialogConfirm'.tr() : confirmText;
    final cancel = cancelText.isEmpty ? 'dialogCancel'.tr() : cancelText;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontFamily: AppTheme.fontFamily)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancel, style: const TextStyle(color: Colors.grey, fontFamily: AppTheme.fontFamily)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirm, style: const TextStyle(color: AppTheme.errorColor, fontFamily: AppTheme.fontFamily)),
          ),
        ],
      ),
    );
  }
}
