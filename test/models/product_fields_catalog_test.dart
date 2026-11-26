import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/products/data/models/product_fields_catalog.dart';
import 'package:hesba/features/products/data/models/product_field.dart';

List<String> _sizesFor(String? businessType) =>
    ProductFieldsCatalog.configFor(
      businessType,
    ).field(ProductFieldKeys.size)?.options ??
    const <String>[];

void main() {
  group('مقاسات المنتجات حسب نوع النشاط', () {
    test('محل الأحذية يعرض مقاسات رقمية وليس مقاسات ملابس', () {
      final sizes = _sizesFor('محل أحذية');

      expect(sizes, contains('38'));
      expect(sizes, contains('40'));
      expect(sizes, contains('42'));
      expect(sizes, isNot(contains('XL')));
      expect(sizes, isNot(contains('M')));
      expect(sizes.last, 'أخرى');
    });

    test('محل الملابس يحتفظ بمقاسات الحروف', () {
      final sizes = _sizesFor('محل ملابس');

      expect(sizes, contains('S'));
      expect(sizes, contains('XL'));
      expect(sizes, isNot(contains('40')));
    });

    test('الأنشطة بدون مقاسات لا تعرض حقل المقاس إطلاقاً', () {
      for (final type in ['سوبر ماركت', 'صيدلية', 'مطعم', 'محل إلكترونيات']) {
        final config = ProductFieldsCatalog.configFor(type);
        expect(config.has(ProductFieldKeys.size), isFalse, reason: type);
        expect(config.businessType, type);
      }
    });

    test('النوع غير المعروف لا يعرض حقل مقاس (السلوك القديم)', () {
      expect(_sizesFor(null), isEmpty);
      expect(_sizesFor('نوع غير مسجل'), isEmpty);
      // دالة المساعد نفسها ترجع مقاسات الملابس كأفضل افتراض.
      expect(
        AppConstants.productSizesFor(null),
        AppConstants.clothingProductSizes,
      );
    });

    test('كل أنواع RegisterConstants لها مقاسات معرّفة', () {
      for (final type in AppConstants.productSizesByBusinessType.keys) {
        expect(AppConstants.productSizesFor(type), isNotEmpty, reason: type);
      }
    });
  });
}
