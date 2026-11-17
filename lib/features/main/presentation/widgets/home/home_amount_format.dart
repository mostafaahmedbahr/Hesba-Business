/// تنسيق مبلغ بدون أصفار عشرية زائدة (نفس أسلوب كروت الـ Home).
String formatHomeAmount(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
