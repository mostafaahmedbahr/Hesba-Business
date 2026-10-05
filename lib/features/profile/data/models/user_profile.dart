/// User profile document read from Firestore.
class UserProfile {
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

  const UserProfile({
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
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      ownerId: json['ownerId'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      shopPhone: json['shopPhone'] as String? ?? '',
      locationUrl: json['locationUrl'] as String? ?? '',
      shopImageUrl: json['shopImageUrl'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
    );
  }

  UserProfile copyWith({
    String? ownerName,
    String? phone,
    String? shopName,
    String? businessType,
    String? shopPhone,
    String? locationUrl,
    String? shopImageUrl,
    String? address,
    String? city,
    String? state,
  }) {
    return UserProfile(
      ownerId: ownerId,
      shopId: shopId,
      ownerName: ownerName ?? this.ownerName,
      email: email,
      phone: phone ?? this.phone,
      shopName: shopName ?? this.shopName,
      businessType: businessType ?? this.businessType,
      shopPhone: shopPhone ?? this.shopPhone,
      locationUrl: locationUrl ?? this.locationUrl,
      shopImageUrl: shopImageUrl ?? this.shopImageUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }
}
