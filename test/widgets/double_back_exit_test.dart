import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/main/presentation/views/main_layout.dart';

/// Double-back-to-exit policy for the main shell.
void main() {
  final now = DateTime(2026, 11, 21, 12, 0);

  test('secondary tab: first back returns home without warning', () {
    expect(
      decideBackAction(currentIndex: 2, lastBackPress: null, now: now),
      BackAction.goHome,
    );
  });

  test('home tab: first back warns instead of exiting', () {
    expect(
      decideBackAction(currentIndex: 0, lastBackPress: null, now: now),
      BackAction.warn,
    );
  });

  test('home tab: second back within 2s exits', () {
    expect(
      decideBackAction(
        currentIndex: 0,
        lastBackPress: now.subtract(const Duration(seconds: 1)),
        now: now,
      ),
      BackAction.exit,
    );
  });

  test('home tab: back after the window warns again', () {
    expect(
      decideBackAction(
        currentIndex: 0,
        lastBackPress: now.subtract(const Duration(seconds: 3)),
        now: now,
      ),
      BackAction.warn,
    );
  });
}
