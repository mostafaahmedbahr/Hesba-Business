import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/accounts/data/repos_impl/accounts_repo_impl.dart';

import '../helpers/test_auth.dart';

/// Checks 6/7: payment recording and the remaining-amount guard in transaction.
void main() {
  late FakeFirebaseFirestore firestore;
  late AccountsRepoImpl repo;

  const uid = 'owner-1';
  const shopId = 'shop-1';

  Future<void> seedDebt({double amount = 100, double paid = 0}) =>
      firestore.collection(AppConstants.debtsCollection).doc('debt-1').set({
        'id': 'debt-1',
        'ownerId': uid,
        'shopId': shopId,
        'personId': 'person-1',
        'personName': 'أحمد',
        'personPhone': '01000000001',
        'partyType': 'customer',
        'direction': 'receivable',
        'amount': amount,
        'paidAmount': paid,
        'note': '',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
      });

  Future<double> paidAmount() async {
    final snap = await firestore.collection(AppConstants.debtsCollection).doc('debt-1').get();
    return (snap.data()!['paidAmount'] as num).toDouble();
  }

  Future<int> paymentCount() async {
    final snap = await firestore
        .collection(AppConstants.debtsCollection)
        .doc('debt-1')
        .collection(AppConstants.debtPaymentsSubCollection)
        .get();
    return snap.docs.length;
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({'shopId': shopId});
    repo = AccountsRepoImpl(auth: signedInAuth(uid), firestore: firestore);
  });

  test('one payment writes one doc and increments paidAmount', () async {
    await seedDebt();
    await repo.addPayment(debtId: 'debt-1', amount: 40, note: 'دفعة');
    expect(await paidAmount(), 40);
    expect(await paymentCount(), 1);
  });

  test('second payment adds another doc — repeat payments are legitimate', () async {
    await seedDebt();
    await repo.addPayment(debtId: 'debt-1', amount: 40);
    await repo.addPayment(debtId: 'debt-1', amount: 60);
    expect(await paidAmount(), 100);
    expect(await paymentCount(), 2);
  });

  test('payment beyond remaining is rejected inside the transaction', () async {
    await seedDebt(paid: 60);
    await expectLater(
      repo.addPayment(debtId: 'debt-1', amount: 50),
      throwsA(isA<Exception>()),
    );
    expect(await paidAmount(), 60);
    expect(await paymentCount(), 0);
  });

  test('exact remaining payment is accepted', () async {
    await seedDebt(paid: 60);
    await repo.addPayment(debtId: 'debt-1', amount: 40);
    expect(await paidAmount(), 100);
    expect(await paymentCount(), 1);

    await expectLater(
      repo.addPayment(debtId: 'debt-1', amount: 0.01),
      throwsA(isA<Exception>()),
    );
    expect(await paidAmount(), 100);
    expect(await paymentCount(), 1);
  });

  test('a payment on another shop debt is rejected', () async {
    await seedDebt();
    await firestore.collection('users').doc(uid).set({'shopId': 'shop-2'});
    await expectLater(
      repo.addPayment(debtId: 'debt-1', amount: 10),
      throwsA(isA<Exception>()),
    );
    expect(await paidAmount(), 0);
    expect(await paymentCount(), 0);
  });
}
