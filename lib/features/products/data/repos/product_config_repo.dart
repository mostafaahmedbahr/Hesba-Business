import '../models/product_form_config.dart';

/// مصدر إعدادات حقول المنتج حسب نشاط المتجر.
abstract class ProductConfigRepo {
  /// يقرأ نوع النشاط التجاري من Firebase ويرجع إعدادات حقول المنتج.
  ///
  /// في حال فشل القراءة أو غياب النوع تُرجَع إعدادات عامة (generic)
  /// حتى تبقى الشاشة صالحة للاستخدام.
  Future<ProductFormConfig> getProductFormConfig();
}
