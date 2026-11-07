import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/features/suppliers/data/repos_impl/suppliers_repo_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

/// كل رسالة خطأ في الـ repo عبارة عن `Exception('supplierErr*')`.
Matcher throwsSupplierError(String key) => throwsA(
  isA<Exception>().having((e) => e.toString(), 'message', contains(key)),
);

/// مخزن مؤقت لكل اختبار — عزل تام بين الحالات.
late FakeFirebaseFirestore db;
late MockFirebaseAuth auth;
late SuppliersRepoImpl repo;

Future<void> seedSupplier(
  String id, {
  required String ownerId,
  required String shopId,
  required String name,
  required String phone,
  String city = '',
}) {
  return db.collection('suppliers').doc(id).set({
    'id': id,
    'ownerId': ownerId,
    'shopId': shopId,
    'name': name,
    'phone': phone,
    'companyName': '',
    'secondaryPhone': '',
    'email': '',
    'address': '',
    'city': city,
    'notes': '',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> seedProduct(
  String id, {
  required String shopId,
  required String ownerId,
  String? supplierId,
  String? supplierName,
  String name = 'منتج',
  num price = 10,
}) {
  return db.collection('products').doc(id).set({
    'id': id,
    'ownerId': ownerId,
    'shopId': shopId,
    'name': name,
    'price': price,
    'costPrice': 5,
    'stock': 3,
    'lowStockThreshold': 1,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    final user = MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);

    await db.collection('users').doc('u1').set({
      'role': 'owner',
      'shopId': 'shop1',
    });

    repo = SuppliersRepoImpl(auth: auth, firestore: db);
  });

  // ═══════════════════════ الإضافة ═══════════════════════

  group('addSupplier', () {
    test(
      'creates a shop-scoped doc with trimmed fields + server times',
      () async {
        final created = await repo.addSupplier(
          name: '   أحمد عبد الله   ',
          phone: '0100 111 2223',
          companyName: '  شركة النور  ',
          city: 'القاهرة',
          notes: ' بيستلم أول الشهر ',
        );

        expect(created.id, isNotEmpty);
        expect(created.name, 'أحمد عبد الله');
        expect(created.companyName, 'شركة النور');

        final stored = (await db.collection('suppliers').doc(created.id).get())
            .data()!;
        expect(stored['ownerId'], 'u1');
        expect(stored['shopId'], 'shop1');
        expect(stored['id'], created.id);
        expect(stored['name'], 'أحمد عبد الله');
        expect(stored['notes'], 'بيستلم أول الشهر');
        expect(stored['createdAt'], isA<Timestamp>());
        expect(stored['updatedAt'], isA<Timestamp>());
      },
    );

    test('rejects a missing name / phone', () async {
      await expectLater(
        repo.addSupplier(name: '', phone: '01001112223'),
        throwsSupplierError('supplierErrNameRequired'),
      );
      await expectLater(
        repo.addSupplier(name: 'مورد', phone: '   '),
        throwsSupplierError('supplierErrPhoneRequired'),
      );
      await expectLater(
        repo.addSupplier(name: 'مورد', phone: ''),
        throwsSupplierError('supplierErrPhoneRequired'),
      );
    });

    test('rejects phones that are not 7..15 digits', () async {
      await expectLater(
        repo.addSupplier(name: 'مورد', phone: '12345'),
        throwsSupplierError('supplierErrPhoneInvalid'),
      );
      await expectLater(
        repo.addSupplier(name: 'مورد', phone: 'not-a-phone'),
        throwsSupplierError('supplierErrPhoneInvalid'),
      );
      await expectLater(
        repo.addSupplier(
          name: 'مورد',
          phone: '1234567890123456', // 16 رقماً
        ),
        throwsSupplierError('supplierErrPhoneInvalid'),
      );
      // 15 رقماً مقبول.
      final ok = await repo.addSupplier(name: 'مورد', phone: '123456789012345');
      expect(ok.id, isNotEmpty);
    });

    test('rejects a duplicate phone in the SAME shop (normalized)', () async {
      await repo.addSupplier(name: 'مورد أ', phone: '01001112223');

      // نفس الرقم بصيغة مختلفة تماماً.
      await expectLater(
        repo.addSupplier(name: 'مورد ب', phone: '0100 111-2223'),
        throwsSupplierError('supplierErrDuplicatePhone'),
      );
      // أرقام عربية → نفس الرقم بعد التوحيد.
      await expectLater(
        repo.addSupplier(name: 'مورد ج', phone: '٠١٠٠١١١٢٢٢٣'),
        throwsSupplierError('supplierErrDuplicatePhone'),
      );
      // وفقط هذا الرقم محجوز: رقم مختلف يمر.
      final other = await repo.addSupplier(
        name: 'مورد د',
        phone: '01111112222',
      );
      expect(other.id, isNotEmpty);
    });

    test('the SAME phone in another shop is not a duplicate', () async {
      // محل آخر يستخدم الرقم نفسه — لا علاقة لنا بيه.
      await seedSupplier(
        'foreign',
        ownerId: 'u2',
        shopId: 'shop2',
        name: 'بائع آخر',
        phone: '01001112223',
      );

      final created = await repo.addSupplier(
        name: 'مورد محلنا',
        phone: '01001112223',
      );
      expect(created.id, isNotEmpty);
    });

    test('throws when signed out or the account has no shop', () async {
      when(() => auth.currentUser).thenReturn(null);
      await expectLater(
        repo.getSuppliers(),
        throwsSupplierError('supplierErrNotSignedIn'),
      );

      final noShopAuth = MockFirebaseAuth();
      final user = MockUser();
      when(() => user.uid).thenReturn('u1');
      when(() => noShopAuth.currentUser).thenReturn(user);
      final noShopRepo = SuppliersRepoImpl(auth: noShopAuth, firestore: db);
      await db.collection('users').doc('u1').set({'role': 'owner'});

      await expectLater(
        noShopRepo.getSuppliers(),
        throwsSupplierError('supplierErrNoShop'),
      );
    });
  });

  // ═══════════════════════ القراءة والعزل ═══════════════════════

  group('shop isolation (read)', () {
    setUp(() async {
      await seedSupplier(
        's1',
        ownerId: 'u1',
        shopId: 'shop1',
        name: 'مورد محلنا',
        phone: '01001112223',
        city: 'القاهرة',
      );
      await seedSupplier(
        's2',
        ownerId: 'u2',
        shopId: 'shop2',
        name: 'بائع محل آخر',
        phone: '01111112222',
        city: 'الإسكندرية',
      );
    });

    test('getSuppliers returns ONLY this shop\'s suppliers', () async {
      final list = await repo.getSuppliers();
      expect(list.map((s) => s.id), ['s1']);
      expect(list.single.shopId, 'shop1');
    });

    test('getSupplierById returns null for another shop\'s supplier', () async {
      expect(await repo.getSupplierById('s1'), isNotNull);
      expect(await repo.getSupplierById('s2'), isNull);
      expect(await repo.getSupplierById('missing'), isNull);
      expect(await repo.getSupplierById(''), isNull);
    });

    test('search never crosses the shop boundary', () async {
      // اسم المورد الآخر لا يظهر أبداً.
      final byName = await repo.searchSuppliers('بائع');
      expect(byName, isEmpty);

      // والرقم الموحّد بتاعه كمان.
      final byPhone = await repo.searchSuppliers('0111 111 2222');
      expect(byPhone, isEmpty);

      // أما موردنا يُوجد بالاسم والشركة والرقم المُنسَّق.
      expect((await repo.searchSuppliers('مورد محلنا')).single.id, 's1');
      expect((await repo.searchSuppliers('0100 111')).single.id, 's1');
      expect((await repo.searchSuppliers('')).map((s) => s.id), ['s1']);
    });

    test('watchSuppliers streams only this shop\'s suppliers', () async {
      final first = await repo.watchSuppliers().first;
      expect(first.map((s) => s.id), ['s1']);
    });
  });

  // ═══════════════════════ التعديل ═══════════════════════

  group('updateSupplier', () {
    late String id;

    setUp(() async {
      final created = await repo.addSupplier(
        name: 'الاسم القديم',
        phone: '01001112223',
        city: 'القاهرة',
        notes: 'ملاحظة قديمة',
      );
      id = created.id;
    });

    test('partial update keeps untouched fields AND ownership', () async {
      final updated = await repo.updateSupplier(
        supplierId: id,
        notes: 'ملاحظة جديدة',
      );

      expect(updated.notes, 'ملاحظة جديدة');
      expect(updated.name, 'الاسم القديم');
      expect(updated.city, 'القاهرة');
      expect(updated.ownerId, 'u1');
      expect(updated.shopId, 'shop1');

      final stored = (await db.collection('suppliers').doc(id).get()).data()!;
      expect(stored['notes'], 'ملاحظة جديدة');
      expect(stored['name'], 'الاسم القديم');
      expect(stored['ownerId'], 'u1');
      expect(stored['shopId'], 'shop1');
      expect(stored['updatedAt'], isA<Timestamp>());
    });

    test('editing everything at once works', () async {
      final updated = await repo.updateSupplier(
        supplierId: id,
        name: 'الاسم الجديد',
        phone: '01111112222',
        companyName: 'شركة محدثة',
        city: ' الجيزة ',
      );
      expect(updated.name, 'الاسم الجديد');
      expect(updated.phone, '01111112222');
      expect(updated.companyName, 'شركة محدثة');
      expect(updated.city, 'الجيزة');
      // التواقيت والملكية كما هي.
      expect(updated.ownerId, 'u1');
      expect(updated.shopId, 'shop1');
      expect(updated.createdAt, isNotNull);
    });

    test('rename syncs the supplierName snapshot on linked products', () async {
      await seedProduct(
        'p1',
        shopId: 'shop1',
        ownerId: 'u1',
        supplierId: id,
        supplierName: 'الاسم القديم',
      );
      await seedProduct(
        'p2',
        shopId: 'shop1',
        ownerId: 'u1',
        supplierId: 'other',
        supplierName: 'غير مرتبط',
      );

      await repo.updateSupplier(supplierId: id, name: 'الاسم الجديد');

      expect(
        (await db.collection('products').doc('p1').get())
            .data()!['supplierName'],
        'الاسم الجديد',
      );
      // منتجات غير مرتبطة لا تتأثر.
      expect(
        (await db.collection('products').doc('p2').get())
            .data()!['supplierName'],
        'غير مرتبط',
      );
    });

    test('a duplicate phone blocks the edit', () async {
      await repo.addSupplier(name: 'مورد آخر', phone: '01111112222');
      await expectLater(
        repo.updateSupplier(supplierId: id, phone: '0111 111 2222'),
        throwsSupplierError('supplierErrDuplicatePhone'),
      );
      // نفس الرقم بتاع المورد نفسه عند التعديل (تجاهل الذات) يمر.
      final ok = await repo.updateSupplier(
        supplierId: id,
        phone: '0100 111 2223',
        name: 'الاسم القديم',
      );
      expect(ok.id, id);
    });

    test('cross-shop / foreign-creator writes are rejected', () async {
      // مورد محل آخر.
      await seedSupplier(
        'foreign',
        ownerId: 'u2',
        shopId: 'shop2',
        name: 'بائع آخر',
        phone: '01234567890',
      );
      await expectLater(
        repo.updateSupplier(supplierId: 'foreign', name: 'X'),
        throwsSupplierError('supplierErrNotAuthorized'),
      );
      await expectLater(
        repo.deleteSupplier('foreign'),
        throwsSupplierError('supplierErrNotAuthorized'),
      );

      // مورد داخل محلنا لكن صنعه مستخدم آخر → التعديل والحذف ممنوعان.
      await seedSupplier(
        'teammate',
        ownerId: 'u2',
        shopId: 'shop1',
        name: 'زميل',
        phone: '01234567891',
      );
      await expectLater(
        repo.updateSupplier(supplierId: 'teammate', name: 'X'),
        throwsSupplierError('supplierErrNotAuthorized'),
      );
      await expectLater(
        repo.deleteSupplier('teammate'),
        throwsSupplierError('supplierErrNotAuthorized'),
      );
      // لكن قراءته مسموحة (داخل نفس المحل).
      expect((await repo.getSupplierById('teammate'))?.name, 'زميل');
    });

    test('unknown supplier id → supplierErrNotFound', () async {
      await expectLater(
        repo.updateSupplier(supplierId: 'nope', name: 'X'),
        throwsSupplierError('supplierErrNotFound'),
      );
      await expectLater(
        repo.updateSupplier(supplierId: '', name: 'X'),
        throwsSupplierError('supplierErrNotFound'),
      );
    });
  });

  // ═══════════════════════ الحذف ═══════════════════════

  group('deleteSupplier', () {
    test('deletes a supplier that has no linked products', () async {
      final created = await repo.addSupplier(
        name: 'هيتشفى',
        phone: '01001112223',
      );
      await repo.deleteSupplier(created.id);
      expect(
        (await db.collection('suppliers').doc(created.id).get()).exists,
        isFalse,
      );
    });

    test(
      'REFUSES to delete when products are linked — nothing is touched',
      () async {
        final created = await repo.addSupplier(
          name: 'مورد مرتبط',
          phone: '01001112223',
        );
        await seedProduct(
          'p1',
          shopId: 'shop1',
          ownerId: 'u1',
          supplierId: created.id,
          supplierName: created.name,
        );

        await expectLater(
          repo.deleteSupplier(created.id),
          throwsSupplierError('supplierErrLinkedProducts'),
        );

        // المورد موجود، والمنتج كما هو حرفياً (لا حذف ولا تعديل صامت).
        expect(
          (await db.collection('suppliers').doc(created.id).get()).exists,
          isTrue,
        );
        final product = (await db.collection('products').doc('p1').get())
            .data()!;
        expect(product['supplierId'], created.id);
        expect(product['supplierName'], created.name);
        expect(product['price'], 10);
      },
    );

    test('products of ANOTHER shop never block the deletion', () async {
      final created = await repo.addSupplier(
        name: 'مورد',
        phone: '01001112223',
      );
      await seedProduct(
        'foreign-product',
        shopId: 'shop2',
        ownerId: 'u2',
        supplierId: created.id,
        supplierName: created.name,
      );

      await repo.deleteSupplier(created.id);
      expect(
        (await db.collection('suppliers').doc(created.id).get()).exists,
        isFalse,
      );
      // ومنتج المحل الآخر لم يُمسّ.
      expect(
        (await db.collection('products').doc('foreign-product').get()).exists,
        isTrue,
      );
    });
  });

  // ═══════════════════════ المنتجات المرتبطة ═══════════════════════

  group('linked products', () {
    setUp(() async {
      await seedSupplier(
        's1',
        ownerId: 'u1',
        shopId: 'shop1',
        name: 'مورد محلنا',
        phone: '01001112223',
      );
      await seedProduct(
        'p1',
        shopId: 'shop1',
        ownerId: 'u1',
        supplierId: 's1',
        supplierName: 'مورد محلنا',
        name: 'منتج 1',
      );
      await seedProduct(
        'p2',
        shopId: 'shop1',
        ownerId: 'u1',
        supplierId: 's1',
        supplierName: 'مورد محلنا',
        name: 'منتج 2',
      );
      await seedProduct(
        'p3',
        shopId: 'shop1',
        ownerId: 'u1',
        supplierId: 's2',
        supplierName: 'مورد ثاني',
        name: 'منتج 3',
      );
      await seedProduct(
        'p4',
        shopId: 'shop2',
        ownerId: 'u2',
        supplierId: 's1', // نفس المعرّف لكن لمحل آخر
        name: 'منتج محل آخر',
      );
      await seedProduct(
        'p5',
        shopId: 'shop1',
        ownerId: 'u1',
        supplierId: null,
        supplierName: null,
        name: 'بدون مورد',
      );
    });

    test('getLinkedProducts is scoped to the shop + the supplier', () async {
      final linked = await repo.getLinkedProducts('s1');
      expect(linked.map((p) => p.id).toSet(), {'p1', 'p2'});
      expect(linked.every((p) => p.shopId == 'shop1'), isTrue);
      expect(linked.every((p) => p.supplierId == 's1'), isTrue);

      expect(await repo.getLinkedProducts(''), isEmpty);
      expect(await repo.getLinkedProducts('nope'), isEmpty);
    });

    test(
      'watchLinkedProductCounts counts per supplier (own shop only)',
      () async {
        final counts = await repo.watchLinkedProductCounts().first;
        expect(counts['s1'], 2);
        expect(counts['s2'], 1);
        expect(counts.containsKey('p5'), isFalse); // بلا مورد
        expect(counts.length, 2); // منتج محل آخر خارج العدّ
      },
    );
  });
}
