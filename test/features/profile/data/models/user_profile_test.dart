import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/profile/data/models/user_profile.dart';

void main() {
  Map<String, dynamic> doc({
    Object? latitude,
    Object? longitude,
    String locationAddress = '',
    String locationUrl = '',
  }) {
    return {
      'ownerId': 'owner-1',
      'shopId': 'shop-1',
      'ownerName': 'أحمد',
      'email': 'a@b.com',
      'phone': '01000000000',
      'shopName': 'محل التجربة',
      'businessType': 'بقالة',
      'shopPhone': '01000000001',
      'locationUrl': locationUrl,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'shopImageUrl': '',
      'address': 'شارع التحرير',
      'city': 'الدقي',
      'state': 'الجيزة',
    };
  }

  test('parses a profile that carries the new location fields', () {
    final profile = UserProfile.fromJson(doc(
      latitude: 30.04442,
      longitude: 31.23571,
      locationAddress: 'الدقي',
      locationUrl:
          'https://www.google.com/maps/search/?api=1&query=30.04442,31.23571',
    ));

    expect(profile.latitude, 30.04442);
    expect(profile.longitude, 31.23571);
    expect(profile.locationAddress, 'الدقي');
    expect(profile.locationUrl,
        'https://www.google.com/maps/search/?api=1&query=30.04442,31.23571');
  });

  test('parses a legacy profile without any location data', () {
    final profile = UserProfile.fromJson(doc());

    expect(profile.latitude, isNull);
    expect(profile.longitude, isNull);
    expect(profile.locationAddress, '');
    expect(profile.locationUrl, '');
  });

  test('copyWith keeps the untouched location fields', () {
    final updated = UserProfile.fromJson(doc()).copyWith(
      latitude: 30.0,
      longitude: 31.0,
      locationAddress: 'الدقي',
      locationUrl: 'https://maps.app.goo.gl/legacy',
    );

    expect(updated.latitude, 30.0);
    expect(updated.longitude, 31.0);
    expect(updated.locationAddress, 'الدقي');
    expect(updated.locationUrl, 'https://maps.app.goo.gl/legacy');
    expect(updated.ownerName, 'أحمد');
    expect(updated.address, 'شارع التحرير');
  });
}
