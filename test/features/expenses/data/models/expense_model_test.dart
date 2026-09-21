import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/features/expenses/data/models/expense_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('ExpenseModel', () {
    test('should create instance with required fields', () {
      final expense = ExpenseModel(
        expenseId: 'exp1',
        ownerId: 'user1',
        shopId: 'shop1',
        title: 'إيجار',
        category: 'إيجار',
        amount: 1000.0,
        note: 'إيجار يناير',
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(expense.expenseId, 'exp1');
      expect(expense.amount, 1000.0);
      expect(expense.title, 'إيجار');
    });

    test('should convert to JSON correctly', () {
      final date = DateTime(2026, 1, 1);
      final createdAt = DateTime(2026, 1, 1);
      final expense = ExpenseModel(
        expenseId: 'exp1',
        ownerId: 'user1',
        shopId: 'shop1',
        title: 'إيجار',
        category: 'إيجار',
        amount: 1000.0,
        note: 'إيجار يناير',
        date: date,
        createdAt: createdAt,
      );
      final json = expense.toJson();
      expect(json['expenseId'], 'exp1');
      expect(json['amount'], 1000.0);
      expect(json['title'], 'إيجار');
      expect(json['date'], isA<Timestamp>());
      expect(json['createdAt'], isA<Timestamp>());
    });

    test('should create from JSON correctly', () {
      final json = {
        'expenseId': 'exp1',
        'ownerId': 'user1',
        'shopId': 'shop1',
        'title': 'إيجار',
        'category': 'إيجار',
        'amount': 1000.0,
        'note': 'إيجار يناير',
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      };
      final expense = ExpenseModel.fromJson(json);
      expect(expense.expenseId, 'exp1');
      expect(expense.amount, 1000.0);
      expect(expense.title, 'إيجار');
      expect(expense.date, DateTime(2026, 1, 1));
      expect(expense.createdAt, DateTime(2026, 1, 1));
    });

    test('should handle Timestamp in fromJson', () {
      final json = {
        'expenseId': 'exp1',
        'ownerId': 'user1',
        'shopId': 'shop1',
        'title': 'إيجار',
        'category': 'إيجار',
        'amount': 1000.0,
        'note': '',
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      };
      final expense = ExpenseModel.fromJson(json);
      expect(expense.date, isA<DateTime>());
      expect(expense.createdAt, isA<DateTime>());
    });

    test('should handle DateTime directly in fromJson', () {
      final json = {
        'expenseId': 'exp1',
        'ownerId': 'user1',
        'shopId': 'shop1',
        'title': 'إيجار',
        'category': 'إيجار',
        'amount': 1000.0,
        'note': '',
        'date': DateTime(2026, 1, 1),
        'createdAt': DateTime(2026, 1, 1),
      };
      final expense = ExpenseModel.fromJson(json);
      expect(expense.date, DateTime(2026, 1, 1));
    });

    test('copyWith should return updated instance', () {
      final expense = ExpenseModel(
        expenseId: 'exp1',
        ownerId: 'user1',
        shopId: 'shop1',
        title: 'إيجار',
        category: 'إيجار',
        amount: 1000.0,
        note: 'إيجار يناير',
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      final updated = expense.copyWith(title: 'رواتب', amount: 2000.0);
      expect(updated.title, 'رواتب');
      expect(updated.amount, 2000.0);
      expect(expense.title, 'إيجار');
    });
  });
}
