class Validators {
  static String? required(String? value, [String message = 'هذا الحقل مطلوب']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// نفس سياسة تسجيل الحساب: موبايل مصري (010/011/012/015) — 11 رقمًا.
  /// يتساهل مع الفواصل (مسافات/شرطات/أقواس/نقاط) والأرقام العربية (٠-٩)
  /// تُحوَّل لاتينية، وبيقبل رقم بصيغة `+20` أو `0020` أو `20XXXXXXXXXX`.
  /// مثال صحيح: 010XXXXXXXX
  static String? egyptianPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'اكتب رقم الهاتف';
    var cleaned = _toLatinDigits(value.trim());
    // شيل كل فاصل وسيب الأرقام و + فقط.
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+20')) {
      // +20 10XXXXXXXX → 010XXXXXXXX
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('0020')) {
      // 0020 10XXXXXXXX → 010XXXXXXXX
      cleaned = '0${cleaned.substring(4)}';
    } else if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    } else if (cleaned.length == 12 && cleaned.startsWith('20')) {
      // 2010XXXXXXXX بدون + → الصيغة المحلية.
      cleaned = '0${cleaned.substring(2)}';
    }
    final regex = RegExp(r'^01[0125][0-9]{8}$');
    if (!regex.hasMatch(cleaned)) {
      return 'رقم الهاتف غير صحيح (مثال: 010XXXXXXXX)';
    }
    return null;
  }

  /// نفس السياسة لكن للحقول الاختيارية: يسمح بالقيمة الفارغة،
  /// وإن كُتِب رقم يجب أن يكون صحيحًا.
  static String? optionalEgyptianPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return egyptianPhone(value);
  }

  /// نفس السياسة لكن للبريد الاختياري: يسمح بالقيمة الفارغة،
  /// وإن كُتِب بريد يجب أن يكون صحيحًا.
  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return email(value);
  }

  /// تحويل الأرقام العربية (٠-٩) والهندية (०-९) إلى لاتينية.
  static String _toLatinDigits(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const indic = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    var out = input;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(arabic[i], '$i').replaceAll(indic[i], '$i');
    }
    return out;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'أدخل البريد الإلكتروني';
    final emailRegex = RegExp(r'^[\w\.\-+]+@([\w-]+\.)+[\w-]{2,63}$');
    if (!emailRegex.hasMatch(value.trim())) return 'البريد الإلكتروني غير صالح';
    return null;
  }

  /// Same policy as change-password: 8+ chars with upper, lower and digit.
  /// (Login never validates strength, so existing 6-char passwords keep working.)
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'أدخل كلمة المرور';
    if (value.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير (A-Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف صغير (a-z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على رقم';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'أكمل كلمة المرور';
    if (value != password) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'أدخل رقم الهاتف';
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim())) return 'رقم الهاتف غير صالح';
    return null;
  }

  static String? number(String? value, [String message = 'أدخل رقم صحيح']) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    if (double.tryParse(value.trim()) == null) return message;
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    final number = double.tryParse(value.trim());
    if (number == null) return 'أدخل رقم صحيح';
    if (number <= 0) return 'يجب أن يكون الرقم أكبر من صفر';
    return null;
  }
}
