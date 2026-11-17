import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/accounts/data/models/person_model.dart';

void main() {
  group('normalizePhone', () {
    test('يزيل المسافات والشرطات والأقواس', () {
      expect(PersonModel.normalizePhone('010-0000 0001'), '01000000001');
      expect(PersonModel.normalizePhone('(010) 0000-0001'), '01000000001');
    });

    test('يحتفظ بعلامة + في الأول فقط كتمييز دولي', () {
      expect(PersonModel.normalizePhone('+20 100 000 0001'), '+201000000001');
    });

    test('يحول الأرقام العربية إلى لاتينية', () {
      expect(PersonModel.normalizePhone('٠١٠٠٠٠٠٠٠٠١'), '01000000001');
    });

    test('يحول الأرقام الهندية إلى لاتينية', () {
      expect(PersonModel.normalizePhone('०१००००००००१'), '01000000001');
    });
  });

  group('mergeType', () {
    test('customer + supplier = both', () {
      expect(PersonModel.mergeType('customer', 'supplier'), PersonModel.typeBoth);
      expect(PersonModel.mergeType('supplier', 'customer'), PersonModel.typeBoth);
    });

    test('نفس النوع يبقى كما هو', () {
      expect(PersonModel.mergeType('customer', 'customer'), 'customer');
      expect(PersonModel.mergeType('both', 'supplier'), 'both');
    });
  });

  group('isCustomer / isSupplier', () {
    test('both يُحتسب كعميل ومورد', () {
      const both = PersonModel(
        id: '1',
        ownerId: 'o',
        shopId: 's',
        name: 'ن',
        phone: '01000000001',
        type: PersonModel.typeBoth,
      );
      expect(both.isCustomer, isTrue);
      expect(both.isSupplier, isTrue);
    });

    test('customer ليس موردًا والعكس', () {
      const customer = PersonModel(
        id: '1',
        ownerId: 'o',
        shopId: 's',
        name: 'ن',
        phone: '01000000001',
        type: PersonModel.typeCustomer,
      );
      const supplier = PersonModel(
        id: '2',
        ownerId: 'o',
        shopId: 's',
        name: 'ن',
        phone: '01000000001',
        type: PersonModel.typeSupplier,
      );
      expect(customer.isSupplier, isFalse);
      expect(supplier.isCustomer, isFalse);
    });
  });
}
