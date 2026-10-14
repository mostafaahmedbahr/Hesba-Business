import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/cubit/shop_location_cubit.dart';
import 'package:hesba/core/cubit/shop_location_state.dart';
import 'package:hesba/core/models/shop_location.dart';
import 'package:hesba/core/services/shop_location_service.dart';

/// Same contract as [ShopLocationService] with every platform call scripted,
/// so the cubit can be tested without GPS/geocoding plugins.
class _FakeShopLocationService extends ShopLocationService {
  ShopLocationFailure? detectFailure;
  Object? detectCrash;
  ShopLocation? detectedLocation;
  String reverseAddress = '';
  ShopLocation? geocodeResult;
  int reverseCalls = 0;
  String? lastGeocodedAddress;

  @override
  Future<ShopLocation> detectCurrentLocation() async {
    final crash = detectCrash;
    if (crash != null) throw crash;
    final failure = detectFailure;
    if (failure != null) throw ShopLocationException(failure);
    return detectedLocation ??
        ShopLocation.fromCoordinates(30.0, 31.0, address: reverseAddress);
  }

  @override
  Future<String> reverseGeocodeAddress(
    double latitude,
    double longitude,
  ) async {
    reverseCalls++;
    return reverseAddress;
  }

  @override
  Future<ShopLocation?> geocodeAddress(String address) async {
    lastGeocodedAddress = address;
    return geocodeResult;
  }
}

void main() {
  late _FakeShopLocationService service;
  late ShopLocationCubit cubit;

  setUp(() {
    service = _FakeShopLocationService();
    cubit = ShopLocationCubit(locationService: service);
  });

  tearDown(() => cubit.close());

  group('initial state', () {
    test('starts idle with no location and no message', () {
      expect(cubit.state.status, ShopLocationStatus.idle);
      expect(cubit.state.location, isNull);
      expect(cubit.state.hasLocation, isFalse);
      expect(cubit.state.isBusy, isFalse);
      expect(cubit.state.messageKey, isNull);
    });
  });

  group('detectCurrentLocation', () {
    test('emits a busy state first, then the picked location', () async {
      service.reverseAddress = 'شارع التحرير، الدقي';
      final emissions = <ShopLocationState>[];
      final subscription = cubit.stream.listen(emissions.add);

      await cubit.detectCurrentLocation();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emissions.first.status, ShopLocationStatus.locating);
      expect(emissions.first.isBusy, isTrue);
      expect(emissions.first.messageKey, isNull);

      expect(cubit.state.status, ShopLocationStatus.success);
      expect(cubit.state.hasLocation, isTrue);
      expect(cubit.state.location?.address, 'شارع التحرير، الدقي');
      expect(cubit.state.location?.locationUrl,
          'https://www.google.com/maps/search/?api=1&query=30.0,31.0');
      expect(cubit.state.messageKey, 'locationPicked');
      expect(cubit.state.messageSeverity, ShopLocationMessageSeverity.success);
    });

    test('maps every failure to its translation key', () async {
      const expected = {
        ShopLocationFailure.serviceDisabled: 'locationServiceOff',
        ShopLocationFailure.permissionDenied: 'locationPermissionDenied',
        ShopLocationFailure.permissionDeniedForever:
            'locationPermissionDeniedForever',
        ShopLocationFailure.timeout: 'locationTimeout',
        ShopLocationFailure.failed: 'locationFailed',
      };

      for (final entry in expected.entries) {
        final failureService = _FakeShopLocationService()
          ..detectFailure = entry.key;
        final failureCubit = ShopLocationCubit(locationService: failureService);

        await failureCubit.detectCurrentLocation();

        expect(failureCubit.state.status, ShopLocationStatus.failure);
        expect(failureCubit.state.messageKey, entry.value);
        expect(
          failureCubit.state.messageSeverity,
          ShopLocationMessageSeverity.error,
        );
        await failureCubit.close();
      }
    });

    test('reports locationFailed when the platform throws anything else',
        () async {
      service.detectCrash = StateError('plugin exploded');

      await cubit.detectCurrentLocation();

      expect(cubit.state.status, ShopLocationStatus.failure);
      expect(cubit.state.messageKey, 'locationFailed');
      expect(cubit.state.messageSeverity, ShopLocationMessageSeverity.error);
      expect(cubit.state.hasLocation, isFalse);
    });
  });

  group('setFromCoordinates', () {
    test('keeps the pin and reverse-geocodes it into an address', () async {
      service.reverseAddress = 'الدقي، الجيزة';

      await cubit.setFromCoordinates(30.04442, 31.23571);

      expect(service.reverseCalls, 1);
      expect(cubit.state.status, ShopLocationStatus.success);
      expect(cubit.state.location?.latitude, 30.04442);
      expect(cubit.state.location?.longitude, 31.23571);
      expect(cubit.state.location?.address, 'الدقي، الجيزة');
      expect(cubit.state.location?.locationUrl,
          'https://www.google.com/maps/search/?api=1&query=30.04442,31.23571');
      expect(cubit.state.messageKey, 'locationPicked');
    });

    test('skips the geocoder when the caller already has an address',
        () async {
      await cubit.setFromCoordinates(30.0, 31.0, address: 'عنوان جاهز');

      expect(service.reverseCalls, 0);
      expect(cubit.state.location?.address, 'عنوان جاهز');
    });
  });

  group('setFromAddress', () {
    test('rejects an empty address', () async {
      await cubit.setFromAddress('   ');

      expect(cubit.state.status, ShopLocationStatus.failure);
      expect(cubit.state.messageKey, 'locationAddressEmpty');
      expect(cubit.state.hasLocation, isFalse);
      expect(service.lastGeocodedAddress, isNull);
    });

    test('resolves a typed address into coordinates', () async {
      service.geocodeResult =
          ShopLocation.fromCoordinates(30.0, 31.0, address: 'الدقي');

      await cubit.setFromAddress('  الدقي  ');

      expect(service.lastGeocodedAddress, 'الدقي');
      expect(cubit.state.status, ShopLocationStatus.success);
      expect(cubit.state.location?.hasCoordinates, isTrue);
      expect(cubit.state.location?.address, 'الدقي');
      expect(cubit.state.messageKey, 'locationPicked');
    });

    test('keeps the text and warns when the address cannot be geocoded',
        () async {
      service.geocodeResult = null;

      await cubit.setFromAddress('عنوان غير معروف');

      expect(cubit.state.status, ShopLocationStatus.success);
      expect(cubit.state.location?.address, 'عنوان غير معروف');
      expect(cubit.state.location?.hasCoordinates, isFalse);
      expect(cubit.state.messageKey, 'locationGeocodeFailed');
      expect(cubit.state.messageSeverity, ShopLocationMessageSeverity.warning);
    });
  });

  group('setFromMapLink', () {
    test('rejects an empty link', () async {
      await cubit.setFromMapLink('   ');

      expect(cubit.state.status, ShopLocationStatus.failure);
      expect(cubit.state.messageKey, 'locationLinkEmpty');
      expect(cubit.state.hasLocation, isFalse);
    });

    test('rejects text that is not a usable link', () async {
      await cubit.setFromMapLink('not a link');

      expect(cubit.state.status, ShopLocationStatus.failure);
      expect(cubit.state.messageKey, 'locationLinkInvalid');
      expect(cubit.state.hasLocation, isFalse);
    });

    test('resolves a share link with coordinates', () async {
      await cubit.setFromMapLink(
        'https://www.google.com/maps/@30.04442,31.23571,17z',
      );

      expect(cubit.state.status, ShopLocationStatus.success);
      expect(cubit.state.hasLocation, isTrue);
      expect(cubit.state.location?.hasCoordinates, isTrue);
      expect(cubit.state.location?.latitude, 30.04442);
      expect(cubit.state.location?.longitude, 31.23571);
      expect(cubit.state.messageKey, 'locationPicked');
      expect(cubit.state.messageSeverity, ShopLocationMessageSeverity.success);
    });

    test('keeps a short link without coordinates', () async {
      await cubit.setFromMapLink('https://maps.app.goo.gl/abc123');

      expect(cubit.state.status, ShopLocationStatus.success);
      expect(cubit.state.hasLocation, isTrue);
      expect(cubit.state.location?.hasCoordinates, isFalse);
      expect(cubit.state.location?.locationUrl, 'https://maps.app.goo.gl/abc123');
    });
  });

  group('restore and clear', () {
    test('restores a stored location silently', () {
      const stored = ShopLocation(
        latitude: 30.0,
        longitude: 31.0,
        address: 'الدقي',
        locationUrl: 'https://maps.app.goo.gl/legacy',
      );

      cubit.restore(stored);

      expect(cubit.state.status, ShopLocationStatus.restored);
      expect(cubit.state.location, stored);
      expect(cubit.state.hasLocation, isTrue);
      expect(cubit.state.messageKey, isNull);
      expect(cubit.state.messageSeverity, isNull);
    });

    test('a null restore leaves the field empty', () {
      cubit.restore(null);

      expect(cubit.state.status, ShopLocationStatus.restored);
      expect(cubit.state.hasLocation, isFalse);
    });

    test('clear drops the location and the message', () async {
      await cubit.setFromCoordinates(30.0, 31.0, address: 'الدقي');

      cubit.clear();

      expect(cubit.state.status, ShopLocationStatus.idle);
      expect(cubit.state.location, isNull);
      expect(cubit.state.messageKey, isNull);
    });
  });
}
