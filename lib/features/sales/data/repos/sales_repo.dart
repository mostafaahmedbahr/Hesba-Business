import '../models/sale_model.dart';

/// عقد مبيعات المحل (كتابة + قراءة).
abstract class SalesRepo {
  Future<SaleModel> addSale({
    required String ownerId,
    required String shopId,
    required List<SaleItemModel> items,
    required double discount,
    required String paymentMethod,
    required String note,
  });

  Future<List<SaleModel>> getSales({required String shopId});

  Stream<List<SaleModel>> watchSales({required String shopId});

  /// id محل اليوزر الحالي (null لو مفيش).
  Future<String?> getShopId();
}
