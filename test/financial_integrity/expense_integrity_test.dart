import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/expenses/data/repos_impl/expenses_repo_impl.dart';

/// Regression for the recurring-expense duplicate-charge race:
/// generated occurrences now use a deterministic document id, so two syncs
/// (or two devices) write the same row instead of two financial charges.
void main() {
  test('occurrence id is deterministic for the same template + due date', () {
    final due = DateTime(2026, 1, 5, 9);
    final a = ExpensesRepoImpl.occurrenceId('template-1', due);
    final b = ExpensesRepoImpl.occurrenceId('template-1', due);
    expect(a, b);
    expect(a, 'template-1_${due.microsecondsSinceEpoch}');
  });

  test('different templates or due slots never collide', () {
    final due = DateTime(2026, 1, 5, 9);
    final other = DateTime(2026, 2, 5, 9);
    final a = ExpensesRepoImpl.occurrenceId('template-1', due);
    final b = ExpensesRepoImpl.occurrenceId('template-2', due);
    final c = ExpensesRepoImpl.occurrenceId('template-1', other);
    expect(a, isNot(b));
    expect(a, isNot(c));
    expect(b, isNot(c));
  });

  test('id is a valid Firestore document id (no slash)', () {
    final id = ExpensesRepoImpl.occurrenceId('tpl', DateTime(2026, 3, 1));
    expect(id.contains('/'), isFalse);
    expect(id.isEmpty, isFalse);
  });
}
