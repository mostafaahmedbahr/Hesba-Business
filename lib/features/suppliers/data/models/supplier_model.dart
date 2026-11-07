import 'package:cloud_firestore/cloud_firestore.dart';

/// مورد (supplier) تابع لمحل واحد.
///
/// البيانات هنا إدارية بحتة: لا توجد مدفوعات ولا مستحقات ولا فواتير شراء.
/// العلاقة مع المنتجات بترجع لـ `products.supplierId` (المفتاح الأساسي)،
/// و`products.supplierName` مجرد لقطة عرض تُحدَّث عند تغيير اسم المورد.
class SupplierModel {
  final String id;
  final String ownerId;
  final String shopId;

  /// اسم المورد (مطلوب).
  final String name;

  /// اسم الشركة/المحال (اختياري).
  final String companyName;

  /// رقم الهاتف الأساسي (مطلوب) — هو أساس كشف التكرار داخل نفس المحل.
  final String phone;

  final String secondaryPhone;
  final String email;
  final String address;
  final String city;
  final String notes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupplierModel({
    required this.id,
    required this.ownerId,
    required this.shopId,
    required this.name,
    required this.phone,
    this.companyName = '',
    this.secondaryPhone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  /// قراءة آمنة من Firestore: كل الحقول الاختيارية الغائبة أو الخاطئة النوع
  /// ترجع قيمتها الافتراضية بدل ما ترمي استثناء (بيانات قديمة/ناقصة).
  factory SupplierModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return SupplierModel(
      id: docId ?? _str(json['id']),
      ownerId: _str(json['ownerId']),
      shopId: _str(json['shopId']),
      name: _str(json['name']),
      companyName: _str(json['companyName']),
      phone: _str(json['phone']),
      secondaryPhone: _str(json['secondaryPhone']),
      email: _str(json['email']),
      address: _str(json['address']),
      city: _str(json['city']),
      notes: _str(json['notes']),
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  /// الحقول القابلة للتعديل فقط — لا تتضمن `ownerId`/`shopId`/التواقيت
  /// الزمنية أبداً، فلا يمكن لأنبوب تعديل أن يعيد تعيين ملكية المورد.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'companyName': companyName,
      'phone': phone,
      'secondaryPhone': secondaryPhone,
      'email': email,
      'address': address,
      'city': city,
      'notes': notes,
    };
  }

  /// المستند الكامل كما يُخزَّن في Firestore (للإنشاء).
  /// يستخدم `FieldValue.serverTimestamp` للإنشاء من الـ repo.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'ownerId': ownerId,
      'shopId': shopId,
      ...toJson(),
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  SupplierModel copyWith({
    String? name,
    String? companyName,
    String? phone,
    String? secondaryPhone,
    String? email,
    String? address,
    String? city,
    String? notes,
  }) {
    return SupplierModel(
      id: id,
      ownerId: ownerId,
      shopId: shopId,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// الاسم المعروض: اسم المورد، ولو فاضي اسم الشركة.
  String get displayName =>
      name.trim().isNotEmpty ? name.trim() : companyName.trim();

  /// الرقم بعد التوحيد — أساس منع التكرار داخل نفس المحل.
  String get normalizedPhone => normalizePhone(phone);

  /// توحيد رقم الهاتف للمقارنة: إزالة المسافات والشرطات والأقواس وعلامة
  /// "+" وتحويل الأرقام العربية/الهندية إلى لاتينية.
  ///
  /// `0100 111-2222` و`+201001112222` و`٠١٠٠١١١٢٢٢٢` تبقى متطابقة؟
  /// لا: نشيل فقط ما يعيق القراءة، ونبقي رمز الدولة لأن مقارنة الرقم
  /// المحلي بالدولي هدفها منع التكرار لا إخفاء فرق حقيقي.
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
