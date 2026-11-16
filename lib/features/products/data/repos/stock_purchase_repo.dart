import '../models/stock_purchase_item.dart';

abstract class StockPurchaseRepo {
  /// تسجيل فاتورة شراء مخزون: يزيد رصيد المنتجات ويسجّل حركة مخزون
  /// لكل صنف داخل transaction واحدة.
  Future<void> addPurchase({
    required String ownerId,
    required String shopId,
    required String shopName,
    required List<StockPurchaseItem> items,
    required double totalAmount,
    required String note,
    required DateTime date,
  });

  Future<String?> getShopId();
  Future<String?> getShopName();
}
