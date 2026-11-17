import 'package:easy_localization/easy_localization.dart';

import '../../../../profile/data/models/user_profile.dart';
import '../../../data/models/sale_model.dart';
import '../../cubit/sales_list_state.dart';

/// معرّف مختصر للفاتورة (نفس منطق كارت المبيعات).
String shortInvoiceId(String saleId) =>
    saleId.length >= 6 ? saleId.substring(0, 6) : saleId;

/// اسم المحل: من البروفايل، وإلا من الفاتورة، وإاسم التطبيق.
String shopNameOf(SaleModel sale, UserProfile? profile) {
  final fromProfile = profile?.shopName.trim() ?? '';
  if (fromProfile.isNotEmpty) return fromProfile;
  final fromSale = sale.shopName.trim();
  if (fromSale.isNotEmpty) return fromSale;
  return 'appName'.tr();
}

/// عنوان المحل: (عنوان • مدينة • محافظة) وإلا العنوان الجغرافي.
String invoiceAddressOf(UserProfile? profile) {
  if (profile == null) return '';
  final parts = [
    profile.address.trim(),
    profile.city.trim(),
    profile.state.trim(),
  ].where((s) => s.isNotEmpty).toList();
  if (parts.isNotEmpty) return parts.join(' • ');
  return profile.locationAddress.trim();
}

/// هاتف المحل (هاتف المحل وإلا رقم صاحب الحساب).
String invoicePhoneOf(UserProfile? profile) {
  if (profile == null) return '';
  final shopPhone = profile.shopPhone.trim();
  if (shopPhone.isNotEmpty) return shopPhone;
  return profile.phone.trim();
}

/// نص الفاتورة المرفق مع الصورة (كـ caption) — يشتغل لوحده لو الصورة
/// ما وصلتش في تطبيق بيخدّف الملفات.
String invoiceShareText(SaleModel sale, {UserProfile? profile}) {
  final currency = 'currencyEGP'.tr();
  final b = StringBuffer();
  b.writeln(
      'salesInvoiceNumber'.tr(namedArgs: {'id': shortInvoiceId(sale.saleId)}));
  b.writeln(shopNameOf(sale, profile));
  final address = invoiceAddressOf(profile);
  if (address.isNotEmpty) b.writeln(address);
  final phone = invoicePhoneOf(profile);
  if (phone.isNotEmpty) b.writeln(phone);
  if (sale.personName.trim().isNotEmpty) {
    b.writeln('${'invoiceCustomer'.tr()}: ${sale.personName.trim()}');
  }
  b.writeln('');
  for (final it in sale.items) {
    final qty = it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1);
    b.writeln('• ${it.productName} × $qty — '
        '${'moneyAmount'.tr(namedArgs: {'total': it.total.toStringAsFixed(2), 'currency': currency})}');
  }
  b.writeln('');
  if (sale.discount > 0) {
    b.writeln(
        '${'salesDiscount'.tr()}: ${sale.discount.toStringAsFixed(2)} $currency');
  }
  b.writeln(
      '${'saleInvoiceTotal'.tr()}: ${'moneyAmount'.tr(namedArgs: {'total': sale.total.toStringAsFixed(2), 'currency': currency})}');
  b.writeln(
      '${'salePaymentMethod'.tr()}: ${SalesListState.paymentLabel(sale.paymentMethod)}');
  return b.toString();
}
