import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// اسم اليوم مختصر (الجمعة..الخميس / Fri..Thu).
String weekdayShort(BuildContext context, int day) {
  final i = day.clamp(1, 7);

  if (context.locale.languageCode == 'ar') {
    const ar = [
      '',
      'جمعة',
      'سبت',
      'أحد',
      'إثنين',
      'ثلاثاء',
      'أربعاء',
      'خميس',
    ];
    return ar[i];
  }

  const en = [
    '',
    'Fri',
    'Sat',
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
  ];

  return en[i];
}

/// اسم اليوم كامل (الجمعة..الخميس / Friday..Thursday).
String weekdayFull(BuildContext context, int day) {
  final i = day.clamp(1, 7);

  if (context.locale.languageCode == 'ar') {
    const ar = [
      '',
      'الجمعة',
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
    ];
    return ar[i];
  }

  const en = [
    '',
    'Friday',
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
  ];

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
