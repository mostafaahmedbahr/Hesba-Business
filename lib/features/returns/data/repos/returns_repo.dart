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
}
