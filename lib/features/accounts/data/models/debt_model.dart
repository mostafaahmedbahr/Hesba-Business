import 'package:cloud_firestore/cloud_firestore.dart';

/// حالة السداد — تُشتق من المبالغ ولا تُخزَّن (مصدر حقيقة واحد).
enum DebtStatus { unpaid, partial, paid }

/// طبيعة العلاقة المالية من وجهة نظر صاحب المحل.
class DebtDirection {
  /// ليّا فلوس (على العميل / عند المورد) — الفلوس داخلة للمحل.
  static const receivable = 'receivable';

  /// عليّ فلوس (للمورد) — الفلوس خارجة من المحل.
  static const payable = 'payable';
}

/// طرف المديونية.
class DebtParty {
  static const customer = 'customer';
  static const supplier = 'supplier';
}

/// سجل مديونية واحد (ذمة). لا يُحذف بعد السداد — يبقى كسجل تدقيق،
/// والدفعات بتتراكم في الـ subcollection `payments`.
class DebtModel {
  final String id;
  final String ownerId;
  final String shopId;

  /// معرّف جهة الاتصال في مجموعة `persons`.
  final String personId;

  /// لقطة الاسم والرقم لحظة التسجيل — لا تتغيّر بتعديل بيانات الشخص.
  final String personName;
  final String personPhone;

  /// customer | supplier.
  final String partyType;

  /// receivable (ليّا) | payable (عليّ). العملاء دائمًا receivable.
  final String direction;

  /// المبلغ الأصلي للمديونية.
  final double amount;

  /// إجمالي المدفوع حتى الآن (يُحدَّث مع كل دفعة عبر transaction).
  final double paidAmount;

  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DebtModel({
    required this.id,
    required this.ownerId,
    required this.shopId,
    required this.personId,
    required this.personName,
    required this.personPhone,
    required this.partyType,
    required this.direction,
    required this.amount,
    this.paidAmount = 0,
    this.note = '',
    this.createdAt,
    this.updatedAt,
  });

  /// المتبقي — لا ينزل تحت الصفر مهما كانت البيانات.
  double get remaining {
    final r = amount - paidAmount;
    return r <= 0 ? 0 : r;
  }

  /// نسبة السداد (0..1) لشريط التقدم.
  double get paidRatio {
    if (amount <= 0) return 1;
    final r = paidAmount / amount;
    return r < 0 ? 0 : (r > 1 ? 1 : r);
  }

  DebtStatus get status {
    if (remaining <= 0) return DebtStatus.paid;
    if (paidAmount > 0) return DebtStatus.partial;
    return DebtStatus.unpaid;
  }

  bool get isReceivable => direction == DebtDirection.receivable;

  String get displayName => personName.trim();

  factory DebtModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return DebtModel(
      id: docId ?? _str(json['id']),
      ownerId: _str(json['ownerId']),
      shopId: _str(json['shopId']),
      personId: _str(json['personId']),
      personName: _str(json['personName']),
      personPhone: _str(json['personPhone']),
      partyType: _str(json['partyType']).isEmpty
          ? DebtParty.customer
          : _str(json['partyType']),
      direction: _str(json['direction']).isEmpty
          ? DebtDirection.receivable
          : _str(json['direction']),
      amount: _num(json['amount']),
      paidAmount: _num(json['paidAmount']),
      note: _str(json['note']),
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  /// المستند كما يُخزَّن عند الإنشاء (بدون التواقيت — repo يضيفها).
  Map<String, dynamic> toJson() {
    return {
      'personId': personId,
      'personName': personName,
      'personPhone': personPhone,
      'partyType': partyType,
      'direction': direction,
      'amount': amount,
      'paidAmount': paidAmount,
      'note': note,
    };
  }

  static String _str(Object? value) => value is String ? value : '';

  static double _num(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
