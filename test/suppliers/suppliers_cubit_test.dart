import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/core/models/product.dart';
import 'package:hesba/features/suppliers/data/repos/suppliers_repo.dart';
import 'package:hesba/features/suppliers/data/models/supplier_model.dart';
import 'package:hesba/features/suppliers/presentation/cubit/supplier_details_cubit.dart';
import 'package:hesba/features/suppliers/presentation/cubit/supplier_form_cubit.dart';
import 'package:hesba/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:hesba/features/suppliers/presentation/states/supplier_details_state.dart';
import 'package:hesba/features/suppliers/presentation/states/supplier_form_state.dart';
import 'package:hesba/features/suppliers/presentation/states/suppliers_state.dart';
import 'package:mocktail/mocktail.dart';

class MockSuppliersRepo extends Mock implements SuppliersRepo {}

SupplierModel supplier({
  String id = 's1',
  String name = 'أحمد عبد الله',
  String phone = '01001112223',
  String city = 'القاهرة',
  String companyName = '',
}) {
  return SupplierModel(
    id: id,
    ownerId: 'u1',
    shopId: 'shop1',
    name: name,
    phone: phone,
    city: city,
    companyName: companyName,
  );
}

Product product(String id, String supplierId) {
  return Product(
    id: id,
    name: 'منتج $id',
    price: 10,
    costPrice: 5,
    stock: 2,
    category: '',
    shopId: 'shop1',
    ownerId: 'u1',
    supplierId: supplierId,
    supplierName: 'مورد',
  );
}

void main() {
  late MockSuppliersRepo repo;

  setUp(() => repo = MockSuppliersRepo());

  // ═══════════════════════ SuppliersCubit ═══════════════════════

  group('SuppliersCubit', () {
    test('init streams suppliers + linked counts → success state', () async {
      when(
        () => repo.watchSuppliers(),
      ).thenAnswer((_) => Stream.value([supplier(), supplier(id: 's2')]));
      when(
        () => repo.watchLinkedProductCounts(),
      ).thenAnswer((_) => Stream.value({'s1': 3}));

      final cubit = SuppliersCubit(repo: repo)..init();
      await pumpEventQueue();

      expect(cubit.state.status, SuppliersStatus.success);
      expect(cubit.state.totalCount, 2);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.linkedCountOf('s1'), 3);
      expect(cubit.state.linkedCountOf('s2'), 0);

      await cubit.close();
    });

    test('empty shop → success with zero (empty state)', () async {
      when(
        () => repo.watchSuppliers(),
      ).thenAnswer((_) => Stream.value(<SupplierModel>[]));
      when(
        () => repo.watchLinkedProductCounts(),
      ).thenAnswer((_) => Stream.value(const <String, int>{}));

      final cubit = SuppliersCubit(repo: repo)..init();
      await pumpEventQueue();

      expect(cubit.state.status, SuppliersStatus.success);
      expect(cubit.state.totalCount, 0);
      expect(cubit.state.filtered, isEmpty);

      await cubit.close();
    });

    test('stream failure → failure status with a message', () async {
      when(
        () => repo.watchSuppliers(),
      ).thenAnswer((_) => Stream<List<SupplierModel>>.error('network down'));
      when(
        () => repo.watchLinkedProductCounts(),
      ).thenAnswer((_) => Stream.value(const <String, int>{}));

      final cubit = SuppliersCubit(repo: repo)..init();
      await pumpEventQueue();

      expect(cubit.state.status, SuppliersStatus.failure);
      expect(cubit.state.errorMessage, contains('network down'));

      await cubit.close();
    });

    test(
      'local search filters by name, company, city and normalized phone',
      () async {
        when(() => repo.watchSuppliers()).thenAnswer(
          (_) => Stream.value([
            supplier(id: 's1', name: 'أحمد', city: 'القاهرة'),
            supplier(
              id: 's2',
              name: 'سمير',
              phone: '01111112222',
              companyName: 'شركة النور',
              city: 'الجيزة',
            ),
          ]),
        );
        when(
          () => repo.watchLinkedProductCounts(),
        ).thenAnswer((_) => Stream.value(const <String, int>{}));

        final cubit = SuppliersCubit(repo: repo)..init();
        await pumpEventQueue();

        // بالاسم.
        cubit.setSearch('أحمد');
        expect(cubit.state.filtered.single.id, 's1');

        // باسم الشركة.
        cubit.setSearch('النور');
        expect(cubit.state.filtered.single.id, 's2');

        // بالمدينة (فلترة الشاشة تشملها).
        cubit.setSearch('الجيزة');
        expect(cubit.state.filtered.single.id, 's2');

        // بالرقم بعد إزالة الفراغات (منطق الموحّد).
        cubit.setSearch('0111 111 2222');
        expect(cubit.state.filtered.single.id, 's2');

        // بلا نتائج → القائمة فاضية والحالة تفضل ناجحة.
        cubit.setSearch('غير موجود');
        expect(cubit.state.filtered, isEmpty);
        expect(cubit.state.status, SuppliersStatus.success);

        // مسح البحث يرجّع الكل.
        cubit.setSearch('');
        expect(cubit.state.filtered, hasLength(2));

        await cubit.close();
      },
    );

    test(
      'deleteSupplier: success clears the error, failure keeps the key',
      () async {
        when(() => repo.deleteSupplier('s1')).thenAnswer((_) async {});
        when(
          () => repo.deleteSupplier('s2'),
        ).thenThrow(Exception('supplierErrLinkedProducts'));

        final cubit = SuppliersCubit(repo: repo);

        expect(await cubit.deleteSupplier('s1'), isTrue);
        expect(cubit.state.errorMessage, isNull);

        expect(await cubit.deleteSupplier('s2'), isFalse);
        expect(cubit.state.errorMessage, 'supplierErrLinkedProducts');

        await cubit.close();
      },
    );

    test('remote search is debounced and only the last query runs', () async {
      when(
        () => repo.searchSuppliers('أح'),
      ).thenAnswer((_) async => [supplier()]);
      when(
        () => repo.searchSuppliers('أحمد'),
      ).thenAnswer((_) async => [supplier()]);
      when(
        () => repo.watchSuppliers(),
      ).thenAnswer((_) => Stream.value(<SupplierModel>[]));
      when(
        () => repo.watchLinkedProductCounts(),
      ).thenAnswer((_) => Stream.value(const <String, int>{}));

      final cubit = SuppliersCubit(repo: repo)..init();
      await pumpEventQueue();

      cubit.searchRemote('أ');
      cubit.searchRemote('أح');
      cubit.searchRemote('أحمد');

      // فوراً بعد النقرات: مفيش أي استدعاء (التأخير 400ms).
      verifyNever(() => repo.searchSuppliers('أ'));
      verifyNever(() => repo.searchSuppliers('أح'));
      verifyNever(() => repo.searchSuppliers('أحمد'));

      await Future<void>.delayed(const Duration(milliseconds: 600));

      // آخر استعلام فقط — واللي قبله أُلغي.
      verifyNever(() => repo.searchSuppliers('أ'));
      verifyNever(() => repo.searchSuppliers('أح'));
      verify(() => repo.searchSuppliers('أحمد')).called(1);

      expect(cubit.state.searching, isFalse);
      expect(cubit.state.remoteResults, hasLength(1));
      expect(cubit.state.pickerResults.single.id, 's1');

      await cubit.close();
    });

    test(
      'empty remote query clears results without hitting the repo',
      () async {
        when(
          () => repo.watchSuppliers(),
        ).thenAnswer((_) => Stream.value(<SupplierModel>[]));
        when(
          () => repo.watchLinkedProductCounts(),
        ).thenAnswer((_) => Stream.value(const <String, int>{}));

        final cubit = SuppliersCubit(repo: repo)..init();
        await pumpEventQueue();

        cubit.searchRemote('   ');
        expect(cubit.state.remoteResults, isNull);
        expect(cubit.state.searching, isFalse);
        verifyNever(() => repo.searchSuppliers(any()));

        await cubit.close();
      },
    );
  });

  // ═══════════════════════ SupplierFormCubit ═══════════════════════

  group('SupplierFormCubit', () {
    SupplierFormCubit filledCubit() {
      final cubit = SupplierFormCubit(repo: repo);
      cubit.onNameChanged('مورد جديد');
      cubit.onPhoneChanged('01001112223');
      cubit.onCompanyNameChanged('شركة');
      cubit.onCityChanged('القاهرة');
      cubit.onNotesChanged('ملاحظات');
      return cubit;
    }

    test('setters fill the state and validate() passes', () async {
      final cubit = filledCubit();
      expect(cubit.state.name, 'مورد جديد');
      expect(cubit.state.phone, '01001112223');
      expect(cubit.state.companyName, 'شركة');
      expect(cubit.state.city, 'القاهرة');
      expect(cubit.validate(), isNull);
      await cubit.close();
    });

    test('validation errors: name then phone (never both at once)', () async {
      final cubit = SupplierFormCubit(repo: repo);

      expect(cubit.validate(), 'supplierErrNameRequired');
      expect(await cubit.submit(), isNull);
      expect(cubit.state.status, SupplierFormStatus.failure);
      expect(cubit.state.errorMessage, 'supplierErrNameRequired');
      verifyNever(
        () => repo.addSupplier(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          companyName: any(named: 'companyName'),
          secondaryPhone: any(named: 'secondaryPhone'),
          email: any(named: 'email'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          notes: any(named: 'notes'),
        ),
      );

      cubit.onNameChanged('مورد');
      expect(cubit.validate(), 'supplierErrPhoneRequired');

      await cubit.close();
    });

    test('successful add → success state + the saved model', () async {
      final cubit = filledCubit();
      when(
        () => repo.addSupplier(
          name: 'مورد جديد',
          phone: '01001112223',
          companyName: 'شركة',
          secondaryPhone: '',
          email: '',
          address: '',
          city: 'القاهرة',
          notes: 'ملاحظات',
        ),
      ).thenAnswer((_) async => supplier(name: 'مورد جديد'));

      final saved = await cubit.submit();

      expect(saved, isNotNull);
      expect(saved!.name, 'مورد جديد');
      expect(cubit.state.status, SupplierFormStatus.success);
      expect(cubit.state.errorMessage, isNull);

      await cubit.close();
    });

    test('repo failure → failure state with the raw key (translateError'
        ' handles the UI)', () async {
      final cubit = filledCubit();
      when(
        () => repo.addSupplier(
          name: 'مورد جديد',
          phone: '01001112223',
          companyName: 'شركة',
          secondaryPhone: '',
          email: '',
          address: '',
          city: 'القاهرة',
          notes: 'ملاحظات',
        ),
      ).thenThrow(Exception('supplierErrDuplicatePhone'));

      final saved = await cubit.submit();

      expect(saved, isNull);
      expect(cubit.state.status, SupplierFormStatus.failure);
      expect(cubit.state.errorMessage, 'supplierErrDuplicatePhone');

      // clearError يشيل الرسالة بعد عرضها.
      cubit.clearError();
      expect(cubit.state.errorMessage, isNull);

      await cubit.close();
    });

    test(
      'double submit is ignored: one write, second call returns null',
      () async {
        final completer = Completer<SupplierModel>();
        var calls = 0;
        when(
          () => repo.addSupplier(
            name: 'مورد جديد',
            phone: '01001112223',
            companyName: 'شركة',
            secondaryPhone: '',
            email: '',
            address: '',
            city: 'القاهرة',
            notes: 'ملاحظات',
          ),
        ).thenAnswer((_) {
          calls++;
          return completer.future;
        });

        final cubit = filledCubit();
        final first = cubit.submit();

        // أثناء الحفظ: الحالة تحذّر من أي ضغطة تانية.
        expect(cubit.state.isSaving, isTrue);
        final second = await cubit.submit();
        expect(second, isNull);
        expect(calls, 1, reason: 'لا يجب إرسال طلبين معاً');

        completer.complete(supplier(name: 'مورد جديد'));
        final result = await first;
        expect(result, isNotNull);
        expect(cubit.state.status, SupplierFormStatus.success);

        await cubit.close();
      },
    );

    test('initForEdit pre-fills every field (edit mode)', () async {
      final cubit = SupplierFormCubit(repo: repo);
      cubit.initForEdit(
        name: 'مورد قديم',
        phone: '01111112222',
        companyName: 'شركة قديمة',
        secondaryPhone: '01000000000',
        email: 'a@b.com',
        address: 'عنوان',
        city: 'الجيزة',
        notes: 'ملاحظة',
      );

      expect(cubit.state.name, 'مورد قديم');
      expect(cubit.state.phone, '01111112222');
      expect(cubit.state.companyName, 'شركة قديمة');
      expect(cubit.state.secondaryPhone, '01000000000');
      expect(cubit.state.email, 'a@b.com');
      expect(cubit.state.address, 'عنوان');
      expect(cubit.state.city, 'الجيزة');
      expect(cubit.state.notes, 'ملاحظة');
      expect(cubit.validate(), isNull);

      await cubit.close();
    });

    test('edit mode submits an update (not an add)', () async {
      when(
        () => repo.updateSupplier(
          supplierId: 's1',
          name: 'مورد جديد',
          phone: '01001112223',
          companyName: 'شركة',
          secondaryPhone: '',
          email: '',
          address: '',
          city: 'القاهرة',
          notes: 'ملاحظات',
        ),
      ).thenAnswer((_) async => supplier(name: 'مورد جديد'));

      final cubit = filledCubit();
      final saved = await cubit.submit(supplierId: 's1');

      expect(saved, isNotNull);
      expect(cubit.state.status, SupplierFormStatus.success);
      verifyNever(
        () => repo.addSupplier(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          companyName: any(named: 'companyName'),
          secondaryPhone: any(named: 'secondaryPhone'),
          email: any(named: 'email'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          notes: any(named: 'notes'),
        ),
      );

      await cubit.close();
    });
  });

  // ═══════════════════════ SupplierDetailsCubit ═══════════════════════

  group('SupplierDetailsCubit', () {
    test('load: supplier + linked products', () async {
      final s = supplier();
      when(() => repo.getSupplierById('s1')).thenAnswer((_) async => s);
      when(
        () => repo.getLinkedProducts('s1'),
      ).thenAnswer((_) async => [product('p1', 's1'), product('p2', 's1')]);

      final cubit = SupplierDetailsCubit(repo: repo);
      await cubit.load('s1');

      expect(cubit.state.status, SupplierDetailsStatus.success);
      expect(cubit.state.supplier?.id, 's1');
      expect(cubit.state.linkedCount, 2);
      expect(cubit.state.linkedProducts.first.id, 'p1');
      expect(cubit.state.busy, isFalse);

      await cubit.close();
    });

    test('load: missing supplier → supplierErrNotFound', () async {
      when(() => repo.getSupplierById('gone')).thenAnswer((_) async => null);

      final cubit = SupplierDetailsCubit(repo: repo);
      await cubit.load('gone');

      expect(cubit.state.status, SupplierDetailsStatus.failure);
      expect(cubit.state.errorMessage, 'supplierErrNotFound');
      expect(cubit.state.supplier, isNull);

      await cubit.close();
    });

    test('load failure → failure status with the repo message', () async {
      when(
        () => repo.getSupplierById('s1'),
      ).thenThrow(Exception('supplierErrNotAuthorized'));

      final cubit = SupplierDetailsCubit(repo: repo);
      await cubit.load('s1');

      expect(cubit.state.status, SupplierDetailsStatus.failure);
      expect(cubit.state.errorMessage, 'supplierErrNotAuthorized');

      await cubit.close();
    });

    test(
      'saveNotes: partial update, busy flag released, error surfaced',
      () async {
        final s = supplier();
        when(() => repo.getSupplierById('s1')).thenAnswer((_) async => s);
        when(
          () => repo.getLinkedProducts('s1'),
        ).thenAnswer((_) async => [product('p1', 's1')]);
        when(
          () => repo.updateSupplier(supplierId: 's1', notes: 'ملاحظة جديدة'),
        ).thenAnswer((_) async => s.copyWith(notes: 'ملاحظة جديدة'));

        final cubit = SupplierDetailsCubit(repo: repo);
        await cubit.load('s1');

        final ok = await cubit.saveNotes('ملاحظة جديدة');
        expect(ok, isTrue);
        expect(cubit.state.busy, isFalse);
        expect(cubit.state.errorMessage, isNull);
        expect(cubit.state.supplier?.notes, 'ملاحظة جديدة');

        await cubit.close();
      },
    );

    test('saveNotes without a loaded supplier does nothing', () async {
      final cubit = SupplierDetailsCubit(repo: repo);
      expect(await cubit.saveNotes('x'), isFalse);
      verifyNever(
        () => repo.updateSupplier(
          supplierId: any(named: 'supplierId'),
          notes: any(named: 'notes'),
        ),
      );
      await cubit.close();
    });

    test('saveNotes failure keeps busy=false and reports the key', () async {
      final s = supplier();
      when(() => repo.getSupplierById('s1')).thenAnswer((_) async => s);
      when(
        () => repo.getLinkedProducts('s1'),
      ).thenAnswer((_) async => const <Product>[]);
      when(
        () => repo.updateSupplier(supplierId: 's1', notes: 'x'),
      ).thenThrow(Exception('supplierErrNotAuthorized'));

      final cubit = SupplierDetailsCubit(repo: repo);
      await cubit.load('s1');

      expect(await cubit.saveNotes('x'), isFalse);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.errorMessage, 'supplierErrNotAuthorized');

      await cubit.close();
    });

    test(
      'delete: success → true; linked products → false + clear message',
      () async {
        final s = supplier();
        when(() => repo.getSupplierById('s1')).thenAnswer((_) async => s);
        when(
          () => repo.getLinkedProducts('s1'),
        ).thenAnswer((_) async => const <Product>[]);
        when(() => repo.deleteSupplier('s1')).thenAnswer((_) async {});
        when(
          () => repo.deleteSupplier('s2'),
        ).thenThrow(Exception('supplierErrLinkedProducts'));

        final cubit = SupplierDetailsCubit(repo: repo);
        await cubit.load('s1');

        expect(await cubit.delete(), isTrue);
        expect(cubit.state.busy, isFalse);

        // مورد تاني مرتبط بمنتجات.
        when(
          () => repo.getSupplierById('s2'),
        ).thenAnswer((_) async => supplier(id: 's2'));
        when(
          () => repo.getLinkedProducts('s2'),
        ).thenAnswer((_) async => const <Product>[]);
        await cubit.load('s2');
        expect(await cubit.delete(), isFalse);
        expect(cubit.state.errorMessage, 'supplierErrLinkedProducts');
        expect(cubit.state.busy, isFalse);

        await cubit.close();
      },
    );

    test('delete is ignored while another action is in flight', () async {
      final s = supplier();
      when(() => repo.getSupplierById('s1')).thenAnswer((_) async => s);
      when(
        () => repo.getLinkedProducts('s1'),
      ).thenAnswer((_) async => const <Product>[]);
      when(() => repo.deleteSupplier('s1')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      final cubit = SupplierDetailsCubit(repo: repo);
      await cubit.load('s1');

      final first = cubit.delete();
      expect(cubit.state.busy, isTrue);
      // ضغطة تانية أثناء الحذف → متجاهلة تماماً.
      expect(await cubit.delete(), isFalse);
      expect(await first, isTrue);
      verify(() => repo.deleteSupplier('s1')).called(1);

      await cubit.close();
    });
  });
}
