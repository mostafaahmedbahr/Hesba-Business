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

    /// اختياري: اسم ورقم العميل. الاتنين لازم يُكتبوا معًا أو يفضلوا
    /// فاضيين. نفس الرقم الموحّد داخل المحل = نفس جهة الاتصال.
    String? customerName,
    String? customerPhone,

    /// Optional idempotency key: used as the sale document id so a retry after
    /// a lost response returns the existing sale instead of writing a duplicate.
    String? requestId,
  });

  Future<List<SaleModel>> getSales({required String shopId});

  Stream<List<SaleModel>> watchSales({required String shopId});

  /// كل فواتير عميل معين (داخل المحل)، الأحدث أولًا — مصدر شاشة
  /// «سجل مشتريات العميل».
  Stream<List<SaleModel>> watchSalesForPerson({
    required String shopId,
    required String personId,
  });

  /// كل فواتير المحل بترقيم cursor (بلا حد صامت) — مصدر حسابات التقارير.
  /// [PagedResult.isComplete] = false يعني أن الجلب توقف قبل النهاية
  /// فيجب عرض الإجماليات كـ"غير مكتملة" لا كأرقام نهائية.
  Future<PagedResult<SaleModel>> fetchAllSales({
    required String shopId,

    /// Server-side lower bound on `createdAt`; avoids downloading full history
    /// when the report only covers recent periods.
    DateTime? from,
  });

  /// حدث خفيف (أثر على أحدث فاتورة) يُعيد تحميل التقارير — بدل الاشتراك
  /// في كل الفواتير. يقرأ مستنداً واحداً فقط.
  Stream<void> watchLatestSale({required String shopId});

  /// id محل اليوزر الحالي (null لو مفيش).
  Future<String?> getShopId();
}
