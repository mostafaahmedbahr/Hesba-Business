import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// عنوان قسم داخل شاشات الـ Home (خط عريض بلون onSurface).
class HomeSectionTitle extends StatelessWidget {
  final String title;
  const HomeSectionTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            fontSize: 15.5.sp,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface));
  }
}
