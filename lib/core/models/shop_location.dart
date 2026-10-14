import 'package:equatable/equatable.dart';

/// Geo data of a shop (registration or profile editing).
///
/// Persisted in the `shops` (and mirrored `users`) document as:
/// * `latitude` / `longitude` — GPS coordinates, `null` when unknown.
/// * `locationUrl` — ready-to-open Google Maps link (auto built from the
///   coordinates when the user never pasted one).
/// * `locationAddress` — address resolved from the coordinates.
///
/// The shop's own `address` field (typed in the shop step) is stored
/// separately and is never overwritten by this value.
class ShopLocation extends Equatable {
  const ShopLocation({
    this.latitude,
    this.longitude,
    this.address = '',
    this.locationUrl = '',
  });

  final double? latitude;
  final double? longitude;

  /// Address resolved from the coordinates (or typed manually by the owner).
  final String address;

  /// Google Maps link, see [buildMapUrl].
  final String locationUrl;

  bool get hasCoordinates => latitude != null && longitude != null;

  /// True when there is anything worth saving/showing (coordinates, address
  /// or a legacy link).
  bool get hasAnyData =>
      hasCoordinates ||
      address.trim().isNotEmpty ||
      locationUrl.trim().isNotEmpty;

  /// Builds the location from coordinates and derives [locationUrl].
  factory ShopLocation.fromCoordinates(
    double latitude,
    double longitude, {
    String address = '',
  }) {
    return ShopLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
      locationUrl: buildMapUrl(latitude, longitude),
    );
  }

  /// Canonical Google Maps link used everywhere in the app:
  /// `https://www.google.com/maps/search/?api=1&query=LATITUDE,LONGITUDE`
  static String buildMapUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  /// Best link to open for a stored shop document.
  ///
  /// Order: a valid legacy [locationUrl] → link built from the coordinates →
  /// link built from the address text → `null` when nothing is available.
  static String? resolveMapUrl({
    String? locationUrl,
    num? latitude,
    num? longitude,
    String? address,
  }) {
    final stored = (locationUrl ?? '').trim();
    if (isValidWebUrl(stored)) return stored;

    final lat = latitude?.toDouble();
    final lng = longitude?.toDouble();
    if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
      return buildMapUrl(lat, lng);
    }

    final text = (address ?? '').trim();
    if (text.isNotEmpty && text != '-') {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(text)}';
    }
    return null;
  }

  /// A location document written by [toMap] / read back by [fromMap].
  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'locationUrl': locationUrl.trim(),
        'locationAddress': address.trim(),
      };

  factory ShopLocation.fromMap(Map<String, dynamic> map) {
    return ShopLocation(
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      address: map['locationAddress'] as String? ?? '',
      locationUrl: map['locationUrl'] as String? ?? '',
    );
  }

  /// http(s) link that can be handed to a browser as-is.
  static bool isValidWebUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasAuthority) return false;
    return uri.isScheme('http') || uri.isScheme('https');
  }

  /// First `lat,lng` pair inside a pasted link (`/@30.1,31.2,17z`,
  /// `?q=30.1,31.2`, `ll=30.1,31.2`, `geo:30.1,31.2`, …).
  static final RegExp _coordinatePair = RegExp(
    r'([-+]?\d{1,3}\.\d+)\s*,\s*([-+]?\d{1,3}\.\d+)',
  );

  /// Parses a location link the owner copied from Google Maps.
  ///
  /// * Link with coordinates → real coordinates (+ the canonical map link).
  /// * Short/human links (`maps.app.goo.gl/…`) → kept as [locationUrl] only,
  ///   the admin's "open on Google Maps" button still works.
  /// * Anything else → `null` (not a usable link).
  static ShopLocation? fromMapLink(String raw) {
    final link = raw.trim();
    if (link.isEmpty) return null;

    final match = _coordinatePair.firstMatch(link);
    if (match != null) {
      final latitude = double.tryParse(match.group(1)!);
      final longitude = double.tryParse(match.group(2)!);
      if (latitude != null &&
          longitude != null &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude >= -180 &&
          longitude <= 180) {
        return ShopLocation.fromCoordinates(latitude, longitude);
      }
    }

    if (isValidWebUrl(link)) {
      return ShopLocation(locationUrl: link);
    }
    return null;
  }

  ShopLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? locationUrl,
  }) {
    return ShopLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      locationUrl: locationUrl ?? this.locationUrl,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, address, locationUrl];
}
