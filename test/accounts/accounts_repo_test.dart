import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/accounts/data/models/debt_model.dart';
import 'package:hesba/features/accounts/data/models/person_model.dart';
import 'package:hesba/features/accounts/data/repos_impl/accounts_repo_impl.dart';

import '../helpers/test_auth.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AccountsRepoImpl repo;

  const uid = 'owner-1';
  const shopId = 'shop-1';

  Future<void> seedUser() async {
    await firestore.collection('users').doc(uid).set({'shopId': shopId});
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await seedUser();
    repo = AccountsRepoImpl(
      auth: signedInAuth(uid),
      firestore: firestore,
    );
  });

  group('addDebt', () {
    test('يضيف مديونية عميل واتجاهها receivable حتى لو طُلب payable', () async {
      final debt = await repo.addDebt(
        name: 'أحمد',
        phone: '01000000001',
        partyType: DebtParty.customer,
        direction: DebtDirection.payable, // محاولات قلب الاتجاه
        amount: 150,
      );
      expect(debt.direction, DebtDirection.receivable);
      expect(debt.partyType, DebtParty.customer);
      expect(debt.amount, 150);
      expect(debt.paidAmount, 0);
      expect(debt.shopId, shopId);

      final saved = await firestore
          .collection(AppConstants.debtsCollection)
          .doc(debt.id)
          .get();
      expect(saved.exists, isTrue);
    });

    test('المورد يُسمح له باتجاه payable', () async {
      final debt = await repo.addDebt(
        name: 'مورد النور',
        phone: '01000000002',
        partyType: DebtParty.supplier,
        direction: DebtDirection.payable,
        amount: 5000,
      );
      expect(debt.direction, DebtDirection.payable);
    });

    test('يرفض مبلغًا صفريًا أو سالبًا', () async {
      await expectLater(
        repo.addDebt(
          name: 'أحمد',
          phone: '01000000001',
          partyType: DebtParty.customer,
          direction: DebtDirection.receivable,
          amount: 0,
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repo.addDebt(
          name: 'أحمد',
          phone: '01000000001',
          partyType: DebtParty.customer,
          direction: DebtDirection.receivable,
          amount: -50,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض اسمًا فاضيًا', () async {
      await expectLater(
        repo.addDebt(
          name: '   ',
          phone: '01000000001',
          partyType: DebtParty.customer,
          direction: DebtDirection.receivable,
          amount: 100,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض رقم هاتف قصير/غير رقمي', () async {
      await expectLater(
        repo.addDebt(
          name: 'أحمد',
          phone: '010',
          partyType: DebtParty.customer,
          direction: DebtDirection.receivable,
          amount: 100,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض نوع طرف غير معروف', () async {
      await expectLater(
        repo.addDebt(
          name: 'أحمد',
          phone: '01000000001',
          partyType: 'employee',
          direction: DebtDirection.receivable,
          amount: 100,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('نفس الرقم لا يُنشئ شخصين — يُعاد استخدام شخص واحد', () async {
      await repo.addDebt(
        name: 'أحمد',
        phone: '010 0000-0001',
        partyType: DebtParty.customer,
        direction: DebtDirection.receivable,
        amount: 100,
      );
      await repo.addDebt(
        name: 'أحمد محمد', // اسم مختلف، نفس الرقم بصيغة تانية
        phone: '010-0000 0001',
        partyType: DebtParty.customer,
        direction: DebtDirection.receivable,
        amount: 200,
      );
      final persons =
          await firestore.collection(AppConstants.personsCollection).get();
      expect(persons.docs, hasLength(1));
      expect(persons.docs.first.data()['type'], PersonModel.typeCustomer);
    });

    test('إضافة مديونية مورد لشخص كان عميلًا تُرقّيه إلى both', () async {
      await repo.addDebt(
        name: 'أحمد',
        phone: '01000000001',
        partyType: DebtParty.customer,
        direction: DebtDirection.receivable,
        amount: 100,
      );
      await repo.addDebt(
        name: 'أحمد',
        phone: '01000000001',
        partyType: DebtParty.supplier,
        direction: DebtDirection.payable,
        amount: 3000,
      );
      final persons =
          await firestore.collection(AppConstants.personsCollection).get();
      expect(persons.docs, hasLength(1));
      expect(persons.docs.first.data()['type'], PersonModel.typeBoth);

      final debts =
          await firestore.collection(AppConstants.debtsCollection).get();
      expect(debts.docs, hasLength(2));
    });
  });

  group('findOrCreatePerson', () {
    test('يُنشئ شخصًا جديدًا ويحفظ الرقم الموحّد', () async {
      final person = await repo.findOrCreatePerson(
        name: 'أحمد',
        phone: '010-0000 0001',
        partyType: PersonModel.typeCustomer,
      );
      final doc = await firestore
          .collection(AppConstants.personsCollection)
          .doc(person.id)
          .get();
      expect(doc.data()!['normalizedPhone'], '01000000001');
    });

    test('الرقم الموجود يُعيد نفس الشخص مع حدّث الاسم', () async {
      final first = await repo.findOrCreatePerson(
        name: 'أحمد',
        phone: '01000000001',
        partyType: PersonModel.typeCustomer,
      );
      final second = await repo.findOrCreatePerson(
        name: 'أحمد محمد',
        phone: '01000000001',
        partyType: PersonModel.typeCustomer,
      );
      expect(second.id, first.id);
      expect(second.name, 'أحمد محمد');
    });

    test('يرفض نوع شخص غير معروف', () async {
      await expectLater(
        repo.findOrCreatePerson(
          name: 'أحمد',
          phone: '01000000001',
          partyType: 'vip',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('addPayment', () {
    /// يبذر مديونية بقيمة 200 على العميل.
    Future<String> seedDebt({double amount = 200, double paid = 0}) async {
      final ref = firestore.collection(AppConstants.debtsCollection).doc('debt-1');
      await ref.set({
        'id': 'debt-1',
        'ownerId': uid,
        'shopId': shopId,
        'personId': 'person-1',
        'personName': 'أحمد',
        'personPhone': '01000000001',
        'partyType': DebtParty.customer,
        'direction': DebtDirection.receivable,
        'amount': amount,
        'paidAmount': paid,
        'note': '',
        'createdAt': DateTime.now(),
      });
      return ref.id;
    }

    test('دفعة صحيحة تُسجّل وتحدّث paidAmount', () async {
      final id = await seedDebt(amount: 200, paid: 50);
      await repo.addPayment(debtId: id, amount: 75);

      final doc = await firestore
          .collection(AppConstants.debtsCollection)
          .doc(id)
          .get();
      expect((doc.data()!['paidAmount'] as num).toDouble(), closeTo(125, 0.001));

      final payments = await firestore
          .collection(AppConstants.debtsCollection)
          .doc(id)
          .collection(AppConstants.debtPaymentsSubCollection)
          .get();
      expect(payments.docs, hasLength(1));
      expect((payments.docs.first.data()['amount'] as num).toDouble(), 75);
      expect(payments.docs.first.data()['shopId'], shopId);
    });

    test('دفعة أكبر من المتبقي تُرفض ولا تُسجّل', () async {
      final id = await seedDebt(amount: 100, paid: 80);
      await expectLater(
        repo.addPayment(debtId: id, amount: 50), // المتبقي 20
        throwsA(isA<Exception>()),
      );
      final doc = await firestore
          .collection(AppConstants.debtsCollection)
          .doc(id)
          .get();
      expect((doc.data()!['paidAmount'] as num).toDouble(), 80);
      final payments = await firestore
          .collection(AppConstants.debtsCollection)
          .doc(id)
          .collection(AppConstants.debtPaymentsSubCollection)
          .get();
      expect(payments.docs, isEmpty);
    });

    test('دفعة بمبلغ صفري أو سالب تُرفض', () async {
      final id = await seedDebt();
      await expectLater(
        repo.addPayment(debtId: id, amount: 0),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repo.addPayment(debtId: id, amount: -10),
        throwsA(isA<Exception>()),
      );
    });

    test('دفعة على مديونية محل آخر تُرفض', () async {
      await seedDebt();
      await firestore
          .collection(AppConstants.debtsCollection)
          .doc('debt-1')
          .update({'shopId': 'shop-other'});
      await expectLater(
        repo.addPayment(debtId: 'debt-1', amount: 10),
        throwsA(isA<Exception>()),
      );
    });

    test('دفعة على مديونية غير موجودة تُرفض', () async {
      await expectLater(
        repo.addPayment(debtId: 'nope', amount: 10),
        throwsA(isA<Exception>()),
      );
    });
  });
}
