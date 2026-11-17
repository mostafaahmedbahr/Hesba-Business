import 'package:flutter/material.dart';

/// وصف باقة سعر (id + عنوان + حقل الإدخال + مدة بالأشهر + لون وأيقونة).
///
/// الكلاس مشترك بين كارت الباقة وملخص التسعير — بيتحمل معاه
/// الـ [TextEditingController] الخاص بالسعر.
class PlanSpec {
  const PlanSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.months,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final int months;
  final IconData icon;
  final Color color;
}
