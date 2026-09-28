import '../models/category_shop_context.dart';

/// عقد تخزين الأقسام (Firestore).
abstract class CategoryRepo {
  /// يجيب بيانات المحل الحالي.
  Future<CategoryShopContext> getShopContext();

  /// يجيب الافتراضي حسب نوع النشاط.
  List<String> defaultCategoriesFor(String? businessType);

  /// ستريم الأقسام المخصصة (live).
  Stream<List<String>> watchCustomCategories(String shopId);

  /// قراءة مرة واحدة للأقسام المخصصة.
  Future<List<String>> getCustomCategories(String shopId);

  /// يضيف قسم جديد.
  Future<void> addCategory(String shopId, String category);

  /// يحذف قسم.
  Future<void> removeCategory(String shopId, String category);
}
