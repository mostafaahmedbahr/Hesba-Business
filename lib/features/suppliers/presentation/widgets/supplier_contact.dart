import '../../../../common_imports.dart';
import '../../../../core/utils/phone_contact.dart';

/// أزرار التفاعل مع هاتف المورد: اتصال + واتساب + نسخ الرقم.
///
/// المنطق الفعلي في [PhoneContact] (core/utils) — هذا الغلاف يبقى للتوافق
/// مع استدعاءات الموردين الحالية.
abstract class SupplierContact {
  const SupplierContact._();

  static String dialablePhone(String raw) => PhoneContact.dialablePhone(raw);

  static bool hasPhone(String raw) => PhoneContact.hasPhone(raw);

  static Future<bool> call(BuildContext context, String phone) =>
      PhoneContact.call(context, phone);

  static Future<bool> whatsapp(BuildContext context, String phone) =>
      PhoneContact.whatsapp(context, phone);

  static Future<void> copyPhone(BuildContext context, String phone) =>
      PhoneContact.copyPhone(context, phone);
}
