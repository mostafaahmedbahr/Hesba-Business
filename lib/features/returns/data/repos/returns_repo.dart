import '../models/return_model.dart';

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
}
