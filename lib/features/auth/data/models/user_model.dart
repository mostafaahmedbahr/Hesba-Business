import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String shopName;
  final String shopId;
  final String phone;
  final String location;
  final String governorate;
  final String center;
  final String shopType;
  final String shopImageUrl;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.shopName,
    required this.shopId,
    required this.phone,
    required this.location,
    required this.governorate,
    required this.center,
    required this.shopType,
    required this.shopImageUrl,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      shopName: data['shopName'] ?? '',
      shopId: data['shopId'] ?? '',
      phone: data['phone'] ?? '',
      location: data['location'] ?? '',
      governorate: data['governorate'] ?? '',
      center: data['center'] ?? '',
      shopType: data['shopType'] ?? '',
      shopImageUrl: data['shopImageUrl'] ?? '',
      role: data['role'] ?? 'cashier',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'shopName': shopName,
      'shopId': shopId,
      'phone': phone,
      'location': location,
      'governorate': governorate,
      'center': center,
      'shopType': shopType,
      'shopImageUrl': shopImageUrl,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? shopName,
    String? shopId,
    String? phone,
    String? location,
    String? governorate,
    String? center,
    String? shopType,
    String? shopImageUrl,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      shopName: shopName ?? this.shopName,
      shopId: shopId ?? this.shopId,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      governorate: governorate ?? this.governorate,
      center: center ?? this.center,
      shopType: shopType ?? this.shopType,
      shopImageUrl: shopImageUrl ?? this.shopImageUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
