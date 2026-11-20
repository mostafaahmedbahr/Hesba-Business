import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hesba/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('يفتح باللغة المحفوظة (إنجليزية) بدل startLocale العربية', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(TranslationProvider(
      child: Builder(
        builder: (context) => MaterialApp(home: Text(context.locale.languageCode)),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('en'), findsOneWidget);
  });

  testWidgets('العربية هي الافتراض لو مفيش لغة محفوظة', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(TranslationProvider(
      child: Builder(
        builder: (context) => MaterialApp(home: Text(context.locale.languageCode)),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ar'), findsOneWidget);
  });
}
