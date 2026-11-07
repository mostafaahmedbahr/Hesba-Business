import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/core/models/product.dart';
import 'package:hesba/features/products/data/repos_impl/products_repo_impl.dart';
import 'package:hesba/features/suppliers/data/repos_impl/suppliers_repo_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

/// تكامل المنتجات × الموردين:
/// 1) حقول المورد اختيارية ولا تكسر المنتجات القديمة.
/// 2) الحفظ يرفض مورّد محل آخر أو معدوماً، ويقبل مورد المحل نفسه.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Product sampleProduct({
    String id = '',
    String? supplierId,
    String? supplierName,
    String shopId = 'shop1',
    String ownerId = 'u1',
  }) {
    return Product(
      id: id,
      name: 'منتج تجريبي',
      price: 100,
      costPrice: 60,
      stock: 7,
      category: 'موبايلات',
      shopId: shopId,
      ownerId: ownerId,
      supplierId: supplierId,
      supplierName: supplierName,
    );
  }

  group('Product model — supplier fields are optional & legacy-safe', () {
    test('legacy JSON without supplier keys reads as null/null', () {
      final product = Product.fromJson(const {
        'name': 'منتج قديم',
        'price': 50,
        'costPrice': 20,
        'stock': 3,
        'category': '',
        'shopId': 'shop1',
        'ownerId': 'u1',
        // لا يوجد supplierId ولا supplierName أصلاً.
      }, docId: 'p1');

      expect(product.supplierId, isNull);
      expect(product.supplierName, isNull);
      expect(product.hasSupplier, isFalse);
      // بقية الحقول كما هي — لا انكسار للسلوك القديم.
      expect(product.id, 'p1');
      expect(product.name, 'منتج قديم');
      expect(product.price, 50);
    });

    test('empty supplierId string is treated as "no supplier"', () {
      final product = Product.fromJson(const {
        'name': 'منتج',
        'supplierId': '',
        'supplierName': '',
      }, docId: 'p1');
      expect(product.hasSupplier, isFalse);
    });

    test('toJson always writes BOTH supplier keys (null when none)', () {
      final withoutSupplier = sampleProduct().toJson();
      expect(withoutSupplier.keys, contains('supplierId'));
      expect(withoutSupplier.keys, contains('supplierName'));
      expect(withoutSupplier['supplierId'], isNull);
      expect(withoutSupplier['supplierName'], isNull);

      final withSupplier = sampleProduct(
        supplierId: 's1',
        supplierName: 'مورد',
      ).toJson();
      expect(withSupplier['supplierId'], 's1');
      expect(withSupplier['supplierName'], 'مورد');
    });

    test('copyWith: omitted keeps, explicit null clears', () {
      final linked = sampleProduct(supplierId: 's1', supplierName: 'مورد');

      // عدم الإرسال = إبقاء القيمة.
      expect(linked.copyWith(name: 'اسم جديد').supplierId, 's1');
      expect(linked.copyWith(name: 'اسم جديد').supplierName, 'مورد');

      // إرسال null صريحاً = إزالة الارتباط.
      final cleared = linked.copyWith(supplierId: null, supplierName: null);
      expect(cleared.supplierId, isNull);
      expect(cleared.supplierName, isNull);
      expect(cleared.hasSupplier, isFalse);

      // تغيير المورد.
      final swapped = linked.copyWith(supplierId: 's2', supplierName: 'مورد 2');
      expect(swapped.supplierId, 's2');
      expect(swapped.supplierName, 'مورد 2');
      // الهوية تبقى.
      expect(swapped.id, linked.id);
      expect(swapped.price, linked.price);
    });
  });

  group('ProductsRepoImpl × supplier reference validation', () {
    late FakeFirebaseFirestore db;
    late MockFirebaseAuth auth;
    late ProductsRepoImpl repo;
    late SuppliersRepoImpl suppliersRepo;

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

      repo = ProductsRepoImpl(auth: auth, firestore: db);
      suppliersRepo = SuppliersRepoImpl(auth: auth, firestore: db);

      // مورد داخل محلنا + مورد محل آخر.
      await suppliersRepo.addSupplier(name: 'مورد محلنا', phone: '01001112223');
      await db.collection('suppliers').doc('foreign').set({
        'id': 'foreign',
        'ownerId': 'u2',
        'shopId': 'shop2',
        'name': 'بائع آخر',
        'phone': '01111112222',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    });

    Future<String> ourSupplierId() async {
      final snap = await db
          .collection('suppliers')
          .where('shopId', isEqualTo: 'shop1')
          .get();
      return snap.docs.first.id;
    }

    test('create: product with a same-shop supplier is saved', () async {
      final supplierId = await ourSupplierId();
      await repo.addProduct(
        sampleProduct(supplierId: supplierId, supplierName: 'مورد محلنا'),
      );

      final all = await db.collection('products').get();
      expect(all.docs, hasLength(1));
      final data = all.docs.single.data();
      expect(data['supplierId'], supplierId);
      expect(data['supplierName'], 'مورد محلنا');
      expect(data['shopId'], 'shop1');
      expect(data['ownerId'], 'u1');
    });

    test('create: product WITHOUT a supplier stores null/null', () async {
      await repo.addProduct(sampleProduct());
      final data = (await db.collection('products').get()).docs.single.data();
      expect(data['supplierId'], isNull);
      expect(data['supplierName'], isNull);
    });

    test(
      'create: another shop\'s supplier is rejected — nothing written',
      () async {
        await expectLater(
          repo.addProduct(
            sampleProduct(supplierId: 'foreign', supplierName: 'بائع آخر'),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('supplierErrNotAuthorized'),
            ),
          ),
        );
        expect((await db.collection('products').get()).docs, isEmpty);

        // مورد معدوم كذلك.
        await expectLater(
          repo.addProduct(
            sampleProduct(supplierId: 'ghost', supplierName: 'أشباح'),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('supplierErrNotAuthorized'),
            ),
          ),
        );
        expect((await db.collection('products').get()).docs, isEmpty);
      },
    );

    test('update: link, change and unlink a supplier', () async {
      await repo.addProduct(sampleProduct());
      final productId = (await db.collection('products').get()).docs.single.id;
      final supplierId = await ourSupplierId();

      // 1) ربط.
      final linked = sampleProduct(
        id: productId,
        supplierId: supplierId,
        supplierName: 'مورد محلنا',
      );
      await repo.updateProduct(linked);
      var data = (await db.collection('products').doc(productId).get()).data()!;
      expect(data['supplierId'], supplierId);
      expect(data['supplierName'], 'مورد محلنا');

      // 2) إزالة الارتباط (null/null صريحاً).
      await repo.updateProduct(
        linked.copyWith(supplierId: null, supplierName: null),
      );
      data = (await db.collection('products').doc(productId).get()).data()!;
      expect(data['supplierId'], isNull);
      expect(data['supplierName'], isNull);
      // باقي بيانات المنتج لم تتأثر.
      expect(data['name'], 'منتج تجريبي');
      expect(data['price'], 100);
    });

    test(
      'update: a foreign supplier is rejected and nothing changes',
      () async {
        final supplierId = await ourSupplierId();
        await repo.addProduct(
          sampleProduct(supplierId: supplierId, supplierName: 'مورد محلنا'),
        );
        final productId =
            (await db.collection('products').get()).docs.single.id;

        await expectLater(
          repo.updateProduct(
            sampleProduct(
              id: productId,
              supplierId: 'foreign',
              supplierName: 'بائع آخر',
            ),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('supplierErrNotAuthorized'),
            ),
          ),
        );

        final data = (await db.collection('products').doc(productId).get())
            .data()!;
        expect(data['supplierId'], supplierId);
        expect(data['supplierName'], 'مورد محلنا');
      },
    );

    test(
      'update: legacy product stays valid (both supplier keys null)',
      () async {
        // مستند قديم بلا حقول مورد أصلاً.
        await db.collection('products').doc('legacy').set({
          'id': 'legacy',
          'ownerId': 'u1',
          'shopId': 'shop1',
          'name': 'منتج قديم',
          'price': 40,
          'costPrice': 20,
          'stock': 2,
          'lowStockThreshold': 1,
          'category': '',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });

        final legacy = Product.fromJson(
          (await db.collection('products').doc('legacy').get()).data()!,
          docId: 'legacy',
        );
        await repo.updateProduct(legacy.copyWith(notes: 'محدّث'));

        final data = (await db.collection('products').doc('legacy').get())
            .data()!;
        expect(data['supplierId'], isNull);
        expect(data['supplierName'], isNull);
        expect(data['notes'], 'محدّث');
      },
    );
  });
}
