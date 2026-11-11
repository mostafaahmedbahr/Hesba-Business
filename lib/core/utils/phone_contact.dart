import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common_imports.dart';

/// أزرار التعامل مع رقم هاتف أي جهة اتصال (عميل / مورد):
/// اتصال + واتساب + نسخ الرقم.
///
/// كل الأرقام تمر عبر [dialablePhone] حتى تعمل مع الأرقام العربية
/// والأرقام المحلية المصرية (010...) ودولي (+20...).
abstract class PhoneContact {
  const PhoneContact._();

  /// تحويل الرقم لصيغة قابلة للاتصال: أرقام لاتينية فقط، والرقم المحلي
  /// المصري يتحول لصيغة دولية (0100... ← 20100...).
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
    // الرقم المحلي المصري (0100...) ← صيغة دولية (20100...).
    if (out.startsWith('0')) out = '20${out.substring(1)}';
    return out;
  }

  static bool hasPhone(String raw) => dialablePhone(raw).length >= 7;

  static Future<bool> call(BuildContext context, String phone) async {
    final digits = dialablePhone(phone);
    if (digits.length < 7) {
      AppToast.warning(context, 'contactPhoneInvalid'.tr());
      return false;
    }
    return _launch(context, Uri(scheme: 'tel', path: digits));
  }

  static Future<bool> whatsapp(BuildContext context, String phone) async {
    final digits = dialablePhone(phone);
    if (digits.length < 7) {
      AppToast.warning(context, 'contactPhoneInvalid'.tr());
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
    AppToast.success(context, 'contactCopied'.tr());
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
      AppToast.error(context, 'contactFailed'.tr());
    }
    return opened;
  }
}
