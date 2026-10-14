import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/models/shop_location.dart';

void main() {
  group('ShopLocation.fromCoordinates', () {
    test('builds the canonical Google Maps link from the coordinates', () {
      final location = ShopLocation.fromCoordinates(30.04442, 31.23571);

      expect(location.latitude, 30.04442);
      expect(location.longitude, 31.23571);
      expect(location.locationUrl,
          'https://www.google.com/maps/search/?api=1&query=30.04442,31.23571');
      expect(location.hasCoordinates, isTrue);
      expect(location.hasAnyData, isTrue);
    });

    test('keeps the reverse-geocoded address next to the coordinates', () {
      final location = ShopLocation.fromCoordinates(
        30.0,
        31.0,
        address: 'شارع التحرير، الدقي',
      );

      expect(location.address, 'شارع التحرير، الدقي');
      expect(location.hasAnyData, isTrue);
    });
  });

  group('ShopLocation state helpers', () {
    test('an empty location carries nothing worth saving', () {
      const location = ShopLocation();

      expect(location.hasCoordinates, isFalse);
      expect(location.hasAnyData, isFalse);
    });

    test('a legacy link alone still counts as data', () {
      const location =
          ShopLocation(locationUrl: 'https://maps.google.com/?q=1,2');

      expect(location.hasCoordinates, isFalse);
      expect(location.hasAnyData, isTrue);
    });

    test('address-only locations count as data too', () {
      const location = ShopLocation(address: '  شارع التحرير  ');

      expect(location.hasAnyData, isTrue);
    });
  });

  group('ShopLocation persistence', () {
    test('toMap uses the Firestore field names', () {
      final location = ShopLocation.fromCoordinates(
        30.04442,
        31.23571,
        address: ' الدقي ',
      );

      expect(location.toMap(), {
        'latitude': 30.04442,
        'longitude': 31.23571,
        'locationUrl':
            'https://www.google.com/maps/search/?api=1&query=30.04442,31.23571',
        'locationAddress': 'الدقي',
      });
    });

    test('round-trips through fromMap/toMap', () {
      final original = ShopLocation.fromCoordinates(
        24.7136,
        46.6753,
        address: 'الرياض',
      );

      final restored = ShopLocation.fromMap(original.toMap());

      expect(restored, original);
    });

    test('reads legacy documents that only carry a link', () {
      final restored = ShopLocation.fromMap({
        'locationUrl': 'https://maps.app.goo.gl/legacy',
      });

      expect(restored.locationUrl, 'https://maps.app.goo.gl/legacy');
      expect(restored.latitude, isNull);
      expect(restored.longitude, isNull);
      expect(restored.address, '');
      expect(restored.hasAnyData, isTrue);
    });

    test('tolerates int coordinates written by Firestore', () {
      final restored = ShopLocation.fromMap({
        'latitude': 30,
        'longitude': 31,
      });

      expect(restored.latitude, 30.0);
      expect(restored.longitude, 31.0);
      expect(restored.hasCoordinates, isTrue);
    });
  });

  group('ShopLocation.fromMapLink', () {
    test('pulls coordinates out of a Google Maps share link', () {
      final location = ShopLocation.fromMapLink(
        'https://www.google.com/maps/@30.04442,31.23571,17z?entry=tts',
      );

      expect(location?.latitude, 30.04442);
      expect(location?.longitude, 31.23571);
      expect(location?.hasCoordinates, isTrue);
      expect(location?.locationUrl,
          'https://www.google.com/maps/search/?api=1&query=30.04442,31.23571');
    });

    test('pulls coordinates out of a ?q= link', () {
      final location = ShopLocation.fromMapLink(
        'https://maps.google.com/?q=24.7136,46.6753',
      );

      expect(location?.latitude, 24.7136);
      expect(location?.longitude, 46.6753);
    });

    test('accepts a geo: URI', () {
      final location = ShopLocation.fromMapLink('geo:30.1,31.2');

      expect(location?.latitude, 30.1);
      expect(location?.longitude, 31.2);
    });

    test('keeps a short link without coordinates as a plain link', () {
      final location =
          ShopLocation.fromMapLink('https://maps.app.goo.gl/abc123');

      expect(location?.hasCoordinates, isFalse);
      expect(location?.locationUrl, 'https://maps.app.goo.gl/abc123');
      expect(location?.hasAnyData, isTrue);
    });

    test('trims surrounding whitespace', () {
      final location =
          ShopLocation.fromMapLink('  https://maps.app.goo.gl/abc123  ');

      expect(location?.locationUrl, 'https://maps.app.goo.gl/abc123');
    });

    test('rejects empty and non-link text', () {
      expect(ShopLocation.fromMapLink(''), isNull);
      expect(ShopLocation.fromMapLink('   '), isNull);
      expect(ShopLocation.fromMapLink('الدقي، الجيزة'), isNull);
    });

    test('ignores out-of-range coordinates', () {
      // No coordinates extracted, but a valid link is still kept as-is.
      final kept = ShopLocation.fromMapLink(
          'https://maps.google.com/@999.0,31.0');
      expect(kept?.hasCoordinates, isFalse);
      expect(kept?.locationUrl, 'https://maps.google.com/@999.0,31.0');

      // Plain text with impossible coordinates is not a usable link.
      expect(ShopLocation.fromMapLink('@999.0,31.0'), isNull);
    });
  });

  group('ShopLocation.resolveMapUrl', () {
    test('prefers a valid stored link', () {
      expect(
        ShopLocation.resolveMapUrl(
          locationUrl: 'https://maps.app.goo.gl/legacy',
          latitude: 30.0,
          longitude: 31.0,
          address: 'الدقي',
        ),
        'https://maps.app.goo.gl/legacy',
      );
    });

    test('falls back to the coordinates when the stored link is broken', () {
      expect(
        ShopLocation.resolveMapUrl(
          locationUrl: 'not a url',
          latitude: 30.0,
          longitude: 31.0,
        ),
        'https://www.google.com/maps/search/?api=1&query=30.0,31.0',
      );
    });

    test('falls back to a search by address text', () {
      expect(
        ShopLocation.resolveMapUrl(
          locationUrl: '',
          address: 'شارع التحرير، الدقي',
        ),
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('شارع التحرير، الدقي')}',
      );
    });

    test('returns null when there is nothing to open', () {
      expect(ShopLocation.resolveMapUrl(), isNull);
      expect(ShopLocation.resolveMapUrl(locationUrl: 'oops'), isNull);
      expect(ShopLocation.resolveMapUrl(latitude: 30.0), isNull);
      expect(ShopLocation.resolveMapUrl(address: '-'), isNull);
    });
  });

  group('ShopLocation.isValidWebUrl', () {
    test('accepts http(s) links only', () {
      expect(ShopLocation.isValidWebUrl('https://maps.app.goo.gl/x'), isTrue);
      expect(ShopLocation.isValidWebUrl('http://example.com'), isTrue);
      expect(ShopLocation.isValidWebUrl('ftp://example.com'), isFalse);
      expect(ShopLocation.isValidWebUrl('maps.app.goo.gl/x'), isFalse);
      expect(ShopLocation.isValidWebUrl(''), isFalse);
    });
  });
}
