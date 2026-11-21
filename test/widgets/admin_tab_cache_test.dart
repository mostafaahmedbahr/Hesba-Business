import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Admin tabs keep their Cubit/data alive across switches. This test models
/// the shell's policy: a page built once is reused, not recreated, so no new
/// Firestore read is triggered on every tab visit.
void main() {
  testWidgets('revisiting a tab reuses the same page instance', (tester) async {
    final created = <int>[];
    final keys = List<GlobalKey>.generate(3, (i) => GlobalKey());
    final pages = List<Widget?>.filled(3, null);

    Widget page(int i) {
      if (pages[i] != null) return pages[i]!;
      created.add(i);
      final w = Placeholder(key: keys[i]);
      pages[i] = w;
      return w;
    }

    Widget stack(int index) => IndexedStack(
          index: index,
          children: List.generate(3, (i) => pages[i] ?? const SizedBox.shrink()),
        );

    page(0); // AdminShell creates the first page in initState.
    await tester.pumpWidget(MaterialApp(home: stack(0)));
    expect(created, [0]);

    page(1); // AdminShell._selectTab creates the page before switching.
    await tester.pumpWidget(MaterialApp(home: stack(1)));
    expect(created, [0, 1]);

    // Return to tab 0: no new page must be created.
    await tester.pumpWidget(MaterialApp(home: stack(0)));
    expect(created, [0, 1]);
  });
}
