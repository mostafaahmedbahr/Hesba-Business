/// بيانات المحل الحالي (shopId + نوع النشاط).
class CategoryShopContext {
  /// id المحل.
  final String shopId;

  /// نوع النشاط (يحدد الافتراضي).
  final String? businessType;

  const CategoryShopContext({required this.shopId, this.businessType});

  /// هل في محل مربوط؟
  bool get hasShop => shopId.isNotEmpty;
}
