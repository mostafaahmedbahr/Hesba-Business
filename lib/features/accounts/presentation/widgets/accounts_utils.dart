import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common_imports.dart';

/// تنسيق المبالغ: أرقام لاتينية بفواصل آلاف، بدون كسور لو العدد صحيح.
String formatMoney(double value) {
  final v = value.abs();
  final isWhole = v == v.roundToDouble();
  final s = _formatGrouped(v, isWhole ? 0 : 2);
  return value < 0 ? '-$s' : s;
}

String _formatGrouped(double v, int fractionDigits) {
  final fixed = v.toStringAsFixed(fractionDigits);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final posFromEnd = intPart.length - i;
    buffer.write(intPart[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
  }
  if (parts.length > 1) {
    buffer.write('.');
    buffer.write(parts[1]);
  }
  return buffer.toString();
}

/// المبلغ + العملة (ج.م / EGP حسب اللغة) — مع fallback آمن لو
/// الترجمات لم تُحمَّل بعد (flutter test / أو أي خطأ مؤقت).
String moneyWithCurrency(double value) {
  final ccy = 'currencyEGP'.tr();
  final suffix = ccy == 'currencyEGP' ? 'ج.م' : ccy;
  return '${formatMoney(value)} $suffix';
}

/// أدوات التفاعل مع رقم هاتف (اتصال / واتساب / نسخ) — نفس منطق
/// `SupplierContact` حتى تعمل الأرقام المحلية والعربية بشكل صحيح.
abstract class AccountContact {
  const AccountContact._();

  /// تحويل الرقم لصيغة قابلة للاتصال: أرقام لاتينية فقط، والرقم المحلي
  /// المصري يتحول لصيغة دولية.
  static String dialablePhone(String raw) {
    var digits = raw.trim();
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (var i = 0; i < 10; i++) {
      digits = digits.replaceAll(arabic[i], '$i');
    }
    final buffer = StringBuffer();
    for (final code in digits.runes) {
      final ch = String.fromCharCode(code);
      if (code >= 0x30 && code <= 0x39) buffer.write(ch);
    }
    var out = buffer.toString();
    if (out.isEmpty) return out;
    if (out.startsWith('00')) out = out.substring(2);
    if (out.startsWith('0')) out = '20${out.substring(1)}';
    return out;
  }

  static bool hasPhone(String raw) => dialablePhone(raw).length >= 7;

  static Future<bool> call(BuildContext context, String phone) async {
    final digits = dialablePhone(phone);
    if (digits.length < 7) {
      AppToast.warning(context, 'رقم الهاتف غير صحيح');
      return false;
    }
    return _launch(context, Uri(scheme: 'tel', path: digits));
  }

  static Future<bool> whatsapp(BuildContext context, String phone) async {
    final digits = dialablePhone(phone);
    if (digits.length < 7) {
      AppToast.warning(context, 'رقم الهاتف غير صحيح');
      return false;
    }
    return _launch(context, Uri.parse('https://wa.me/$digits'));
  }

  static Future<void> copyPhone(BuildContext context, String phone) async {
    final digits = dialablePhone(phone);
    await Clipboard.setData(
      ClipboardData(text: digits.isEmpty ? phone : digits),
    );
    if (!context.mounted) return;
    AppToast.success(context, 'تم نسخ الرقم');
  }

  static Future<bool> _launch(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      if (await canLaunchUrl(uri)) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      opened = false;
    }
    if (!context.mounted) return opened;
    if (!opened) {
      AppToast.error(context, 'تعذر فتح التطبيق — تأكد أن تطبيق الاتصال متاح');
    }
    return opened;
  }
}

/// يعرض Bottom Sheet أنيق بخيارات الاتصال بالرقم (اتصال / واتساب / نسخ).
void showPhoneActionsSheet(BuildContext context, String phone) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          12.w,
          0,
          12.w,
          MediaQuery.of(sheetContext).padding.bottom + 12.h,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
            ),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // المقبض + الرقم.
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: AppTheme.paleSlate,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.phone_rounded,
                      color: AppTheme.primaryColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التواصل عبر الرقم',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTheme.ink,
                          ),
                        ),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slateGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _PhoneActionTile(
                icon: Icons.call_rounded,
                label: 'اتصال مباشر',
                subtitle: 'فتح لوحة الاتصال',
                color: AppTheme.successDark,
                onTap: () {
                  Navigator.pop(sheetContext);
                  AccountContact.call(context, phone);
                },
              ),
              SizedBox(height: 8.h),
              _PhoneActionTile(
                icon: Icons.chat_rounded,
                label: 'واتساب',
                subtitle: 'فتح محادثة WhatsApp مع الرقم',
                color: const Color(0xFF25D366),
                onTap: () {
                  Navigator.pop(sheetContext);
                  AccountContact.whatsapp(context, phone);
                },
              ),
              SizedBox(height: 8.h),
              _PhoneActionTile(
                icon: Icons.copy_rounded,
                label: 'نسخ الرقم',
                subtitle: 'نسخ إلى الحافظة',
                color: AppTheme.primaryColor,
                onTap: () {
                  Navigator.pop(sheetContext);
                  AccountContact.copyPhone(context, phone);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PhoneActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PhoneActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 19.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slateGray,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.mutedGray, size: 19.sp),
            ],
          ),
        ),
      ),
    );
  }
}
