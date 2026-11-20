import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/utils/validators.dart';

void main() {
  group('Validators.egyptianPhone', () {
    test('يقبل رقم مصري صحيح', () {
      expect(Validators.egyptianPhone('01110690299'), isNull);
      expect(Validators.egyptianPhone('01012345678'), isNull);
    });

    test('يرفض كلمة أو حروف مع الرقم (نفس تحقق إنشاء الحساب)', () {
      expect(Validators.egyptianPhone('واتحدث01110690299'), isNotNull);
      expect(Validators.egyptianPhone('01110690299 واتحدث'), isNotNull);
      expect(Validators.egyptianPhone('abc01110690299'), isNotNull);
    });

    test('يظل متساهل مع الفواصل والصيغة الدولية', () {
      expect(Validators.egyptianPhone('011 1069 0299'), isNull);
      expect(Validators.egyptianPhone('+20 111 069 0299'), isNull);
      expect(Validators.egyptianPhone('٠١١١٠٦٩٠٢٩٩'), isNull);
    });

    test('يرفض الأرقام غير المصرية', () {
      expect(Validators.egyptianPhone('01310690299'), isNotNull);
      expect(Validators.egyptianPhone('123'), isNotNull);
    });
  });
}
