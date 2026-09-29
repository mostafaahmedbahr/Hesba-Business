import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// اسم اليوم مختصر (إثنين..أحد / Mon..Sun).
String weekdayShort(BuildContext context, int day) {
  final i = day.clamp(1, 7);
  if (context.locale.languageCode == 'ar') {
    const ar = ['', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
    return ar[i];
  }
  const en = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return en[i];
}

/// اسم اليوم كامل.
String weekdayFull(BuildContext context, int day) {
  final i = day.clamp(1, 7);
  if (context.locale.languageCode == 'ar') {
    const ar = ['', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return ar[i];
  }
  const en = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return en[i];
}

/// الوقت كنص (12h + صباحًا/مساءً).
String timeText(BuildContext context, int hour, int minute) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final mm = minute.toString().padLeft(2, '0');
  if (context.locale.languageCode != 'ar') {
    return '$h12:$mm ${hour >= 12 ? 'PM' : 'AM'}';
  }
  return '$h12:$mm ${hour >= 12 ? 'مساءً' : 'صباحًا'}';
}
