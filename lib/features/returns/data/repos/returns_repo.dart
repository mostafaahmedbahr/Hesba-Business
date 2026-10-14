import '../../../sales/data/models/sale_model.dart';
import '../models/return_model.dart';

/// عقد مرتجعات المحل (كتابة + قراءة).
abstract class ReturnsRepo {
  Future<ReturnModel> addReturn({
    required String ownerId,
    required String shopId,
    String? originalSaleId,
    required List<ReturnItemModel> items,
    required String reason,
    required String note,
  });

  Future<List<ReturnModel>> getReturns({required String shopId});

  Stream<List<ReturnModel>> watchReturns({required String shopId});

  /// id محل اليوزر الحالي (null لو مفيش).
  Future<String?> getShopId();

  /// Latest sales of a shop for the return picker (newest first, capped).
  Stream<List<SaleModel>> watchShopSales({required String shopId});

  /// Already-returned quantities per product key for a sale, used to cap
  /// editable quantities. Throws on read failure (caller fails closed).
  Future<Map<String, double>> getAlreadyReturnedQuantities(String saleId);
}
