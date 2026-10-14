import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/auth/data/models/register_model.dart';

void main() {
  RegisterModel build({
    double? latitude,
    double? longitude,
    String locationUrl = '',
    String locationAddress = '',
  }) {
    return RegisterModel(
      ownerId: 'owner-1',
      shopId: 'shop-1',
      ownerName: 'أحمد',
      email: 'a@b.com',
      phone: '01000000000',
      shopName: 'محل التجربة',
      businessType: 'بقالة',
      shopPhone: '01000000001',
      locationUrl: locationUrl,
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
      shopImageUrl: 'https://cdn/x.png',
      address: 'شارع التحرير',
      city: 'الدقي',
      state: 'الجيزة',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      isActive: true,
    );
  }

  test('serializes the shop location fields for Firestore', () {
    final json = build(
      latitude: 30.04442,
      longitude: 31.23571,
      locationUrl: 'https://www.google.com/maps/search/?api=1&query=30.04442,31.23571',
      locationAddress: 'الدقي',
    ).toJson();

    expect(json['latitude'], 30.04442);
    expect(json['longitude'], 31.23571);
    expect(
      json['locationUrl'],
      'https://www.google.com/maps/search/?api=1&query=30.04442,31.23571',
    );
    expect(json['locationAddress'], 'الدقي');
  });

  test('leaves the location null for a manual/legacy registration', () {
    final json = build().toJson();

    expect(json['latitude'], isNull);
    expect(json['longitude'], isNull);
    expect(json['locationUrl'], '');
    expect(json['locationAddress'], '');
    expect(json['address'], 'شارع التحرير');
  });

  test('keeps the typed shop address untouched next to the location fields',
      () {
    final json = build(
      latitude: 30.0,
      longitude: 31.0,
      locationAddress: 'العنوان المستخرج من الإحداثيات',
    ).toJson();

    expect(json['address'], 'شارع التحرير');
    expect(json['locationAddress'], 'العنوان المستخرج من الإحداثيات');
  });
}
