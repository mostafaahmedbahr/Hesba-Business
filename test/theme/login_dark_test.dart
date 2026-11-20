import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/auth/presentation/widgets/login_widgets/login_text_field.dart';

void main() {
  testWidgets('حقول اللوجن تستخدم ألوان الوضع الداكن', (tester) async {
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: LoginTextField(
            controller: TextEditingController(),
            label: 'Email',
            hint: 'name@example.com',
            icon: Icons.email_outlined,
          ),
        ),
      ),
    ));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.fillColor, AppTheme.darkSurfaceAlt);
    expect(
      (field.decoration!.border as OutlineInputBorder).borderSide.color,
      AppTheme.darkBorder,
    );
  });
}
