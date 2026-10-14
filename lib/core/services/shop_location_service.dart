import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/shop_location.dart';

/// Why a location attempt failed — mapped to a translation key by the
/// presentation layer.
enum ShopLocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  failed,
}

class ShopLocationException implements Exception {
  const ShopLocationException(this.failure);

  final ShopLocationFailure failure;

  @override
  String toString() => 'ShopLocationException(${failure.name})';
}

/// Data-layer access to the device GPS and the platform geocoder
/// (reverse: coordinates → address, forward: address → coordinates).
///
/// Every method is overridable so tests can fake the whole service.
class ShopLocationService {
  /// True when the device has location services (GPS) turned on.
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Asks for the location permission when needed and returns the current
  /// position together with the best address we could resolve.
  ///
  /// Throws a [ShopLocationException] describing what went wrong
  /// (permission denied, GPS off, timeout, …).
  Future<ShopLocation> detectCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ShopLocationException(ShopLocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const ShopLocationException(ShopLocationFailure.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ShopLocationException(
        ShopLocationFailure.permissionDeniedForever,
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
    } on TimeoutException {
      throw const ShopLocationException(ShopLocationFailure.timeout);
    } catch (_) {
      throw const ShopLocationException(ShopLocationFailure.failed);
    }

    // The address is a bonus — never fail the GPS fix because of it.
    final address = await reverseGeocodeAddress(
      position.latitude,
      position.longitude,
    );
    return ShopLocation.fromCoordinates(
      position.latitude,
      position.longitude,
      address: address,
    );
  }

  /// Best-effort address for the given coordinates; empty string when the
  /// platform geocoder is unavailable/offline.
  Future<String> reverseGeocodeAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) return '';
      return formatPlacemark(placemarks.first);
    } catch (_) {
      return '';
    }
  }

  /// Resolves a typed address into coordinates. Returns `null` when the
  /// address cannot be resolved (offline, unknown place, …).
  Future<ShopLocation?> geocodeAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;
    try {
      final results = await Geocoding().locationFromAddress(query);
      if (results.isEmpty) return null;
      final first = results.first;
      return ShopLocation.fromCoordinates(
        first.latitude,
        first.longitude,
        address: query,
      );
    } catch (_) {
      return null;
    }
  }

  /// Last known position without prompting for permission; `null` when the
  /// device has nothing cached.
  Future<ShopLocation?> lastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      return ShopLocation.fromCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  /// Joins the non-empty placemark parts into one readable address.
  static String formatPlacemark(Placemark place) {
    final parts = <String>[];
    final seen = <String>{};

    void add(String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return;
      if (!seen.add(text)) return;
      parts.add(text);
    }

    add(place.subThoroughfare);
    add(place.thoroughfare);
    add(place.subLocality);
    add(place.locality);
    add(place.administrativeArea);
    add(place.country);

    if (parts.isNotEmpty) return parts.join('، ');
    return (place.name ?? '').trim();
  }
}
