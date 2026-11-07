import '../../../../core/models/product.dart';
import '../models/supplier_model.dart';

/// عمليات ميزة الموردين.
///
/// كل العمليات محصورة داخل محل المستخدم الحالي (`ownerId` + `shopId`) —
/// لا يمكن قراءة أو تعديل أو حذف مورد لمحل آخر مهما كان المعرّف.
abstract class SuppliersRepo {
  /// معرّف المحل الحالي (`null` لو المستخدم غير مسجّل أو المحل لسه مش متظبط).
  Future<String?> getShopId();

  /// قائمة حيّة لموردي المحل الحالي (الأحدث أولاً).
  Stream<List<SupplierModel>> watchSuppliers();

  /// لقطة واحدة لموردي المحل الحالي.
  Future<List<SupplierModel>> getSuppliers();

  /// مورد واحد بمعرّفه — يرجع `null` لو غير موجود أو تابع لمحل آخر.
  Future<SupplierModel?> getSupplierById(String supplierId);

  /// يضيف مورداً جديداً للمحل الحالي.
  ///
  /// يرمي استثناءً برسالة `supplierErr*` عند غياب الحقول المطلوبة أو
  /// وجود مورد بنفس الرقم الموحّد داخل نفس المحل.
  Future<SupplierModel> addSupplier({
    required String name,
    required String phone,
    String companyName = '',
    String secondaryPhone = '',
    String email = '',
    String address = '',
    String city = '',
    String notes = '',
  });

  /// يعدّل حقول مورد موجود.
  ///
  /// أي حقل بقي `null` يُترك كما هو (لذا تعديل الملاحظات وحدها مسموح).
  /// `ownerId` و`shopId` و`createdAt` تُقرأ من المستند المخزَّن ولا تُؤخذ
  /// من المتصل أبداً.
  Future<SupplierModel> updateSupplier({
    required String supplierId,
    String? name,
    String? phone,
    String? companyName,
    String? secondaryPhone,
    String? email,
    String? address,
    String? city,
    String? notes,
  });

  /// يحذف مورداً — يمنع الحذف لو فيه منتجات مرتبطة به.
  Future<void> deleteSupplier(String supplierId);

  /// بحث داخل موردي المحل الحالي بالاسم أو اسم الشركة أو رقم الهاتف.
  Future<List<SupplierModel>> searchSuppliers(String query);

  /// عدد المنتجات المرتبطة بكل مورد داخل المحل الحالي (معرّف المورد → العدد).
  ///
  /// مصدر واحد لشارة "المنتجات المرتبكة" في بطاقات القائمة.
  Stream<Map<String, int>> watchLinkedProductCounts();

  /// المنتجات المرتبطة بمورد معين داخل المحل الحالي فقط.
  Future<List<Product>> getLinkedProducts(String supplierId);
}
