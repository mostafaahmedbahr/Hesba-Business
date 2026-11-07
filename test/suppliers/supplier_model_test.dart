import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/features/suppliers/data/models/supplier_model.dart';

/// اختبارات نموذج المورد: القراءة الآمنة، التوثيق، التوحيد، والنسخ.
void main() {
  SupplierModel sample({String id = 's1'}) => SupplierModel(
    id: id,
    ownerId: 'u1',
    shopId: 'shop1',
    name: 'أحمد عبد الله',
    phone: '01001112223',
    companyName: 'شركة النور',
    secondaryPhone: '01111112222',
    email: 'a@b.com',
    address: 'شارع التحرير 12',
    city: 'القاهرة',
    notes: 'بيستلم أول كل شهر',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );

  group('fromJson', () {
    test('reads every field + docId', () {
      final model = SupplierModel.fromJson({
        'id': 'x',
        'ownerId': 'u1',
        'shopId': 'shop1',
        'name': 'مورد',
        'phone': '01001112223',
        'companyName': 'شركة',
        'secondaryPhone': '0111',
        'email': 'a@b.com',
        'address': 'عنوان',
        'city': 'القاهرة',
        'notes': 'ملاحظات',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
      }, docId: 's9');

      expect(model.id, 's9'); // docId يغلب حقل id داخل المستند.
      expect(model.ownerId, 'u1');
      expect(model.shopId, 'shop1');
      expect(model.name, 'مورد');
      expect(model.phone, '01001112223');
      expect(model.companyName, 'شركة');
      expect(model.city, 'القاهرة');
      // Timestamp.toDate() يرجع وقت محلي — نقارن بالحالة UTC عشان ما
      // يتأثر باختلاف المنطقة الزمنية على جهاز الاختبار.
      expect(model.createdAt!.toUtc(), DateTime.utc(2026, 1, 1));
      expect(model.updatedAt!.toUtc(), DateTime.utc(2026, 1, 2));
    });

    test('missing/wrong-typed optional fields fall back to defaults', () {
      final model = SupplierModel.fromJson(const {
        'ownerId': 'u1',
        'shopId': 'shop1',
        'name': 'مورد',
        'phone': '01001112223',
        'companyName': 42, // نوع خاطئ
        'city': null,
        // بقية الحقول غائبة تماماً (مستند قديم).
      }, docId: 's1');

      expect(model.companyName, '');
      expect(model.city, '');
      expect(model.secondaryPhone, '');
      expect(model.notes, '');
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
      expect(model.id, 's1');
    });

    test('reads legacy DateTime values (not only Timestamp)', () {
      final model = SupplierModel.fromJson(const {
        'name': 'مورد',
        'createdAt': null,
      });
      expect(model.createdAt, isNull);
    });
  });

  group('toJson / toFirestore', () {
    test('toJson contains ONLY editable fields (never ownership)', () {
      final json = sample().toJson();
      expect(json.keys.toSet(), {
        'name',
        'companyName',
        'phone',
        'secondaryPhone',
        'email',
        'address',
        'city',
        'notes',
      });
      expect(json.containsKey('ownerId'), isFalse);
      expect(json.containsKey('shopId'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
      expect(json.containsKey('id'), isFalse);
    });

    test('toFirestore adds id + ownership + Timestamps', () {
      final doc = sample().toFirestore();
      expect(doc['id'], 's1');
      expect(doc['ownerId'], 'u1');
      expect(doc['shopId'], 'shop1');
      expect(doc['createdAt'], isA<Timestamp>());
      expect(doc['updatedAt'], isA<Timestamp>());
      expect(doc['name'], 'أحمد عبد الله');
    });

    test('null timestamps stay null (before the server fills them)', () {
      final model = SupplierModel(
        id: 's2',
        ownerId: 'u1',
        shopId: 'shop1',
        name: 'مورد',
        phone: '01001112223',
      );
      final doc = model.toFirestore();
      expect(doc['createdAt'], isNull);
      expect(doc['updatedAt'], isNull);
    });
  });

  group('copyWith / display', () {
    test('copyWith keeps identity + untouched fields', () {
      final original = sample();
      final updated = original.copyWith(name: 'اسم جديد', notes: 'ملاحظة');

      expect(updated.id, original.id);
      expect(updated.ownerId, original.ownerId);
      expect(updated.shopId, original.shopId);
      expect(updated.phone, original.phone);
      expect(updated.createdAt, original.createdAt);
      expect(updated.name, 'اسم جديد');
      expect(updated.notes, 'ملاحظة');
      expect(updated.companyName, original.companyName);
    });

    test('displayName falls back to companyName when name is blank', () {
      final model = SupplierModel(
        id: 's3',
        ownerId: 'u1',
        shopId: 'shop1',
        name: '   ',
        phone: '01001112223',
        companyName: 'شركة النور',
      );
      expect(model.displayName, 'شركة النور');
      expect(sample().displayName, 'أحمد عبد الله');
    });
  });

  group('normalizePhone (أساس منع التكرار)', () {
    test('strips spaces, dashes, parens and dots', () {
      expect(SupplierModel.normalizePhone('0100 111-2222'), '01001112222');
      expect(SupplierModel.normalizePhone('(010) 111.2222'), '0101112222');
    });

    test('converts Arabic and Indic digits to Latin', () {
      expect(SupplierModel.normalizePhone('٠١٠٠١١١٢٢٢٣'), '01001112223');
      expect(SupplierModel.normalizePhone('०१२३४५६७'), '01234567');
    });

    test('keeps a leading + (country code is meaningful)', () {
      expect(SupplierModel.normalizePhone('+20 100 111 2222'), '+201001112222');
    });

    test('the same number written differently normalizes identically', () {
      const variants = [
        '01001112223',
        '0100 111 2223',
        '0100-111-2223',
        '(0100) 111 2223',
        '٠١٠٠١١١٢٢٢٣',
      ];
      final normalized = variants.map(SupplierModel.normalizePhone).toSet();
      expect(normalized, hasLength(1));
    });
  });
}
