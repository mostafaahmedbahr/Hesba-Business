import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// يسأل "إصدار فاتورة؟" بعد حفظ البيع — يرجع true لو اختار المستخدم الإصدار.
Future<bool> askIssueInvoice(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppTheme.primaryColor, size: 22),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'invoiceAskTitle'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'invoiceAskMessage'.tr(),
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.6,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: Text(
            'dialogCancel'.tr(),
            style: const TextStyle(
                color: Colors.grey, fontFamily: AppTheme.fontFamily),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: Text(
            'invoiceIssue'.tr(),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
