import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/expenses/data/models/expense_model.dart';
import 'package:hesba/features/expenses/data/repos_impl/expenses_repo_impl.dart';

import '../helpers/test_auth.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ExpensesRepoImpl repo;

  const uid = 'owner-1';
  const shopId = 'shop-1';

  ExpensesRepoImpl buildRepo({String? signedInUid = uid}) {
    return ExpensesRepoImpl(
      firestore: firestore,
      auth: signedInUid == null ? signedOutAuth() : signedInAuth(signedInUid),
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = buildRepo();
  });

  group('addExpense validation', () {
    test('يرفض عنوانًا فاضيًا', () async {
      await expectLater(
        repo.addExpense(
          ownerId: uid,
          shopId: shopId,
          shopName: 'محلي',
          title: '  ',
          category: 'إيجار',
          amount: 100,
          note: '',
          date: DateTime(2026, 1, 1),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض مبلغًا صفريًا أو سالبًا', () async {
      await expectLater(
        repo.addExpense(
          ownerId: uid,
          shopId: shopId,
          shopName: 'محلي',
          title: 'إيجار',
          category: 'إيجار',
          amount: 0,
          note: '',
          date: DateTime(2026, 1, 1),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض بدون تصنيف', () async {
      await expectLater(
        repo.addExpense(
          ownerId: uid,
          shopId: shopId,
          shopName: 'محلي',
          title: 'إيجار',
          category: '',
          amount: 100,
          note: '',
          date: DateTime(2026, 1, 1),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('المصروف المكرر بدون موعد استحقاق يُرفض', () async {
      await expectLater(
        repo.addExpense(
          ownerId: uid,
          shopId: shopId,
          shopName: 'محلي',
          title: 'إيجار',
          category: 'إيجار',
          amount: 100,
          note: '',
          date: DateTime(2026, 1, 1),
          recurrence: ExpenseModel.recurrenceMonthly,
          dueTime: '', // ناقص
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('addExpense happy path (غير متكرر)', () {
    test('يُحفظ المصروف بدون nextDue ولا يتسبب في جدولة', () async {
      final expense = await repo.addExpense(
        ownerId: uid,
        shopId: shopId,
        shopName: 'محلي',
        title: 'إيجار يناير',
        category: 'إيجار',
        amount: 1500,
        note: 'شهر يناير',
        date: DateTime(2026, 1, 1),
      );
      expect(expense.nextDue, isNull);
      final doc = await firestore
          .collection(AppConstants.expensesCollection)
          .doc(expense.expenseId)
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['title'], 'إيجار يناير');
      expect(doc.data()!['shopId'], shopId);
      expect(doc.data()!['ownerId'], uid);
    });
  });

  group('getExpenses isolation', () {
    test('يرجع مصاريف المحل فقط ولا يسرّب محلًا آخر', () async {
      await repo.addExpense(
        ownerId: uid,
        shopId: shopId,
        shopName: 'محلي',
        title: 'مصروف محلي',
        category: 'إيجار',
        amount: 100,
        note: '',
        date: DateTime(2026, 1, 1),
      );
      // مستند من محل آخر يُبذر مباشرة.
      await firestore.collection(AppConstants.expensesCollection).doc('other-1').set({
        'expenseId': 'other-1',
        'ownerId': 'other-owner',
        'shopId': 'shop-other',
        'shopName': 'محل آخر',
        'title': 'مصروف آخر',
        'category': 'إيجار',
        'amount': 999,
        'note': '',
        'date': DateTime(2026, 1, 1).toUtc(),
        'createdAt': DateTime(2026, 1, 1).toUtc(),
      });
      final list = await repo.getExpenses(shopId: shopId);
      expect(list, hasLength(1));
      expect(list.first.title, 'مصروف محلي');
    });
  });

  group('deleteExpense', () {
    test('يحذف مصروف المالك', () async {
      final expense = await repo.addExpense(
        ownerId: uid,
        shopId: shopId,
        shopName: 'محلي',
        title: 'كهرباء',
        category: 'مرافق',
        amount: 300,
        note: '',
        date: DateTime(2026, 2, 1),
      );
      await repo.deleteExpense(expenseId: expense.expenseId, shopId: shopId);
      final doc = await firestore
          .collection(AppConstants.expensesCollection)
          .doc(expense.expenseId)
          .get();
      expect(doc.exists, isFalse);
    });

    test('يرفض حذف مصروف محل آخر', () async {
      await firestore.collection(AppConstants.expensesCollection).doc('other-1').set({
        'expenseId': 'other-1',
        'ownerId': 'other-owner',
        'shopId': 'shop-other',
        'shopName': 'محل آخر',
        'title': 'مصروف آخر',
        'category': 'إيجار',
        'amount': 999,
        'note': '',
        'date': DateTime(2026, 1, 1).toUtc(),
        'createdAt': DateTime(2026, 1, 1).toUtc(),
      });
      await expectLater(
        repo.deleteExpense(expenseId: 'other-1', shopId: shopId),
        throwsA(isA<Exception>()),
      );
    });
  });
}
