class RegisterModel {
  final String ownerId;
  final String shopId;

  final String ownerName;
  final String email;
  final String phone;

  final String shopName;
  final String businessType;
  final String shopPhone;

  final String locationUrl;
  final String shopImageUrl;

  final String address;
  final String city;
  final String state;

  final DateTime createdAt;
  final DateTime updatedAt;

  final bool isActive;

  const RegisterModel({
    required this.ownerId,
    required this.shopId,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.shopName,
    required this.businessType,
    required this.shopPhone,
    required this.locationUrl,
    required this.shopImageUrl,
    required this.address,
    required this.city,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });
  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'shopId': shopId,
      'ownerName': ownerName,
      'email': email,
      'phone': phone,
      'shopName': shopName,
      'businessType': businessType,
      'shopPhone': shopPhone,
      'locationUrl': locationUrl,
      'shopImageUrl': shopImageUrl,
      'address': address,
      'city': city,
      'state': state,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }
}

