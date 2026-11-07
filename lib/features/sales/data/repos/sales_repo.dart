import '../../../../core/utils/paged_fetch.dart';
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

  /// كل فواتير المحل بترقيم cursor (بلا حد صامت) — مصدر حسابات التقارير.
  /// [PagedResult.isComplete] = false يعني أن الجلب توقف قبل النهاية
  /// فيجب عرض الإجماليات كـ"غير مكتملة" لا كأرقام نهائية.
  Future<PagedResult<SaleModel>> fetchAllSales({required String shopId});

  /// حدث خفيف (أثر على أحدث فاتورة) يُعيد تحميل التقارير — بدل الاشتراك
  /// في كل الفواتير. يقرأ مستنداً واحداً فقط.
  Stream<void> watchLatestSale({required String shopId});

  /// id محل اليوزر الحالي (null لو مفيش).
  Future<String?> getShopId();
}
