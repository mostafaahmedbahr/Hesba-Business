import '../models/category_shop_context.dart';

/// عقد تخزين الأقسام (Firestore).
abstract class CategoryRepo {
  /// يجيب بيانات المحل الحالي.
  Future<CategoryShopContext> getShopContext();

  /// يجيب الافتراضي حسب نوع النشاط.
  List<String> defaultCategoriesFor(String? businessType);

  /// قراءة مرة واحدة للأقسام المخصصة (عند فتح الشاشة / بعد التعديل).
  Future<List<String>> getCustomCategories(String shopId);

  /// يضيف قسم جديد.
  Future<void> addCategory(String shopId, String category);

  /// يحذف قسم.
  Future<void> removeCategory(String shopId, String category);
}
