import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HesbaApp());
    await tester.pumpAndSettle();
  });
}
