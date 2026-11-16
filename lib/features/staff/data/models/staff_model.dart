import 'package:cloud_firestore/cloud_firestore.dart';

/// حساب فرعي تابع لمحل صاحب المحل. لا يعرض أي بيانات مالية —
/// يُستخدم فقط في شاشة إدارة الحسابات الفرعية الخاصة بالصاحب.
class StaffModel {
  final String uid;
  final String ownerId;
  final String shopId;
  final String name;
  final String email;
  final String phone;
  final bool isActive;
  final DateTime? createdAt;

  const StaffModel({
    required this.uid,
    required this.ownerId,
    required this.shopId,
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    this.createdAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json, {required String docId}) {
    return StaffModel(
      uid: (json['uid'] as String?) ?? docId,
      ownerId: (json['ownerId'] as String?) ?? '',
      shopId: (json['shopId'] as String?) ?? '',
      name: (json['name'] as String?) ?? (json['ownerName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
