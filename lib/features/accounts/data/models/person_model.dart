import 'package:cloud_firestore/cloud_firestore.dart';

/// جهة اتصال موحّدة داخل المحل (عميل / مورد / الاثنين).
///
/// نفس الشخص يُستخدم في مديونيات العملاء ومستحقات الموردين بدون تكرار
/// الإدخال — مفتاح التمييز هو رقم الهاتف الموحّد داخل نفس المحل.
class PersonModel {
  /// الشخص عميل فقط.
  static const typeCustomer = 'customer';

  /// الشخص مورد فقط.
  static const typeSupplier = 'supplier';

  /// الشخص عميل ومورد في نفس الوقت.
  static const typeBoth = 'both';

  final String id;
  final String ownerId;
  final String shopId;
  final String name;
  final String phone;

  /// نوع الشخص: customer | supplier | both.
  final String type;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PersonModel({
    required this.id,
    required this.ownerId,
    required this.shopId,
    required this.name,
    required this.phone,
    this.type = typeCustomer,
    this.createdAt,
    this.updatedAt,
  });

  /// قراءة آمنة من Firestore — الحقول الغائبة أو الخاطئة ترجع قيمتها
  /// الافتراضية بدل ما ترمي استثناء (بيانات قديمة/ناقصة).
  factory PersonModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return PersonModel(
      id: docId ?? _str(json['id']),
      ownerId: _str(json['ownerId']),
      shopId: _str(json['shopId']),
      name: _str(json['name']),
      phone: _str(json['phone']),
      type: _str(json['type']).isEmpty ? typeCustomer : _str(json['type']),
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  /// الحقول القابلة للتعديل فقط — لا تتضمن `ownerId`/`shopId`/التواقيت.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'type': type,
    };
  }

  PersonModel copyWith({String? name, String? phone, String? type}) {
    return PersonModel(
      id: id,
      ownerId: ownerId,
      shopId: shopId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// الاسم المعروض.
  String get displayName => name.trim();

  /// الرقم بعد التوحيد — أساس منع التكرار داخل نفس المحل.
  String get normalizedPhone => normalizePhone(phone);

  /// هل هذا الشخص مورد؟ (مورد فقط أو الاثنين).
  bool get isSupplier => type == typeSupplier || type == typeBoth;

  /// هل هذا الشخص عميل؟ (عميل فقط أو الاثنين).
  bool get isCustomer => type == typeCustomer || type == typeBoth;

  /// دمج نوع جديد مع النوع الحالي بدون فقدان المعلومة:
  /// عميل + مورد = both.
  static String mergeType(String current, String incoming) {
    if (current == incoming) return current;
    if (current == typeBoth || incoming == typeBoth) return typeBoth;
    return typeBoth; // customer + supplier
  }

  /// توحيد رقم الهاتف للمقارنة: إزالة المسافات والشرطات والأقواس
  /// وعلامة "+" وتحويل الأرقام العربية/الهندية إلى لاتينية.
  static String normalizePhone(String raw) {
    final digits = _toLatinDigits(raw);
    final buffer = StringBuffer();
    for (final code in digits.runes) {
      final ch = String.fromCharCode(code);
      if (ch == '+' ||
          ch == ' ' ||
          ch == '-' ||
          ch == '(' ||
          ch == ')' ||
          ch == '.' ||
          ch == '/') {
        if (ch == '+') buffer.write(ch);
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString().trim();
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

  static String _str(Object? value) => value is String ? value : '';

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
