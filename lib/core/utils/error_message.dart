import 'package:easy_localization/easy_localization.dart';

/// Translates cubit error keys (`saleErr*`, `retErr*`, `purchaseErr*`,
/// `supplierErr*`) with their args.
///
/// Anything else (raw Firebase/SDK messages, Arabic legacy strings) passes
/// through untouched, so catch-all handlers never show a raw key.
String translateError(String? message, [Map<String, String>? args]) {
  if (message == null || message.isEmpty) return 'errorGeneric'.tr();
  if (message.startsWith('saleErr') ||
      message.startsWith('retErr') ||
      message.startsWith('purchaseErr') ||
      message.startsWith('supplierErr')) {
    return args == null || args.isEmpty
        ? message.tr()
        : message.tr(namedArgs: args);
  }
  final lower = message.toLowerCase();
  if (lower.contains('permission-denied') ||
      lower.contains('permission denied') ||
      lower.contains('insufficient permission')) {
    return 'الصلاحية مرفوضة: تأكد أن حساب الموظف مُفعّل ومرتبط بالمحل، وأن اشتراك صاحب المحل ساري.';
  }
  return message;
}
