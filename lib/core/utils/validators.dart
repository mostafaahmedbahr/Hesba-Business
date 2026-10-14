class Validators {
  static String? required(String? value, [String message = 'هذا الحقل مطلوب']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'أدخل البريد الإلكتروني';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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
