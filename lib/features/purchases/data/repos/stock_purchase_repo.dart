import '../models/stock_purchase_model.dart';
import '../stock_purchase_calculator.dart';

/// عمليات ميزة زيادة المخزون (فواتير الشراء وتحديث المخزون).
abstract class StockPurchaseRepo {
  /// معرّف فاتورة جديد (يُنشأ مرة واحدة لكل جلسة إرسال ويُعاد استخدامه في
  /// إعادة المحاولة — حماية من التكرار لو العملية نجحت فعلاً والرد ضاع).
  String generatePurchaseId();

  /// يسجل فاتورة شراء وحدة في معاملة Firestore ذرّية واحدة:
  /// تحديث المخزون + متوسط سعر الشراء لكل منتج، إنشاء الفاتورة، وإنشاء
  /// حركات المخزون. أي فشل يُفشل العملية كاملة بدون تحديث جزئي.
  ///
  /// الحساب كله يُعاد من داخل المعاملة من القيم الموثوقة للمنتجات —
  /// لا يُعتمد على أي قيمة محسوبة أرسلتها الواجهة.
  Future<StockPurchase> addPurchase({
    required String purchaseId,
    required String ownerId,
    required String shopId,
    String supplierName,
    String supplierPhone,
    String invoiceNumber,
    required DateTime purchaseDate,
    String notes,
    required List<PurchaseLineInput> lines,
  });
}
