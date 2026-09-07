abstract class RegisterConstants {
  static const List<String> businessTypes = [
    'سوبر ماركت',
    'بقالة',
    'محل خضروات',
    'محل فواكه',
    'محل لحوم',
    'محل أسماك',
    'صيدلية',
    'محل ملابس',
    'محل إلكترونيات',
    'محل عطور',
    'محل أحذية',
    'محل أدوات منزلية',
    'محل ورد',
    'كافيه',
    'مطعم',
    'محل حلويات',
    'محل حلاقة',
    'غير ذلك',
  ];

  static const List<String> governorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'القليوبية',
    'البحيرة',
    'الشرقية',
    'الدقهلية',
    'الغربية',
    'المنوفية',
    'كفر الشيخ',
    'الفيوم',
    'بني سويف',
    'مطروح',
    'الوادي الجديد',
    'أسوان',
    'قنا',
    'الأقصر',
    'البحر الأحمر',
    'دمياط',
    'الإسماعيلية',
    'بورسعيد',
    'السويس',
    'شمال سيناء',
    'جنوب سيناء',
    'أسيوط',
    'سوهاج',
    'المنيا',
  ];

  static String? validateEgyptianPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'اكتب رقم الهاتف';
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    final regex = RegExp(r'^01[0125][0-9]{8}$');
    if (!regex.hasMatch(cleaned)) return 'رقم الهاتف غير صحيح (مثال: 010XXXXXXXX)';
    return null;
  }
}
