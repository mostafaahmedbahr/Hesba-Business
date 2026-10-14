import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/shop_location.dart';
import '../services/shop_location_service.dart';
import 'shop_location_state.dart';

/// Presentation-layer state of the shop-location picker.
///
/// Shared by registration and profile editing so both screens follow exactly
/// the same flow: GPS → map pin → typed address, with the resulting
/// coordinates / address / Google Maps link kept in one place.
class ShopLocationCubit extends Cubit<ShopLocationState> {
  ShopLocationCubit({required ShopLocationService locationService})
      : _locationService = locationService,
        super(const ShopLocationState());

  final ShopLocationService _locationService;

  /// GPS fix: permission handling, position and reverse-geocoded address.
  Future<void> detectCurrentLocation() async {
    emit(state.copyWith(
      status: ShopLocationStatus.locating,
      clearMessage: true,
    ));
    try {
      final location = await _locationService.detectCurrentLocation();
      emit(_success(location));
    } on ShopLocationException catch (error) {
      emit(state.copyWith(
        status: ShopLocationStatus.failure,
        messageKey: _errorKey(error.failure),
        messageSeverity: ShopLocationMessageSeverity.error,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ShopLocationStatus.failure,
        messageKey: 'locationFailed',
        messageSeverity: ShopLocationMessageSeverity.error,
      ));
    }
  }

  /// Pin dropped on the interactive map (address resolved best-effort).
  Future<void> setFromCoordinates(
    double latitude,
    double longitude, {
    String address = '',
  }) async {
    emit(state.copyWith(
      status: ShopLocationStatus.geocoding,
      clearMessage: true,
    ));
    final resolved = address.trim().isNotEmpty
        ? address.trim()
        : await _locationService.reverseGeocodeAddress(latitude, longitude);
    emit(_success(ShopLocation.fromCoordinates(
      latitude,
      longitude,
      address: resolved,
    )));
  }

  /// A Google Maps link pasted by the owner: coordinates when the link
  /// carries them, otherwise the link itself (still openable by the admin).
  Future<void> setFromMapLink(String raw) async {
    final link = raw.trim();
    if (link.isEmpty) {
      emit(state.copyWith(
        status: ShopLocationStatus.failure,
        messageKey: 'locationLinkEmpty',
        messageSeverity: ShopLocationMessageSeverity.error,
      ));
      return;
    }
    final location = ShopLocation.fromMapLink(link);
    if (location == null) {
      emit(state.copyWith(
        status: ShopLocationStatus.failure,
        messageKey: 'locationLinkInvalid',
        messageSeverity: ShopLocationMessageSeverity.error,
      ));
      return;
    }
    emit(_success(location));
  }

  /// Address typed by the owner: converted into coordinates when possible,
  /// otherwise kept as text only (still valid for legacy readers).
  Future<void> setFromAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) {
      emit(state.copyWith(
        status: ShopLocationStatus.failure,
        messageKey: 'locationAddressEmpty',
        messageSeverity: ShopLocationMessageSeverity.error,
      ));
      return;
    }

    emit(state.copyWith(
      status: ShopLocationStatus.geocoding,
      clearMessage: true,
    ));
    final resolved = await _locationService.geocodeAddress(query);
    if (resolved != null) {
      emit(_success(resolved));
      return;
    }
    emit(ShopLocationState(
      status: ShopLocationStatus.success,
      location: ShopLocation(address: query),
      messageKey: 'locationGeocodeFailed',
      messageSeverity: ShopLocationMessageSeverity.warning,
    ));
  }

  /// Prefills the picker from a stored profile — silent, no success toast.
  void restore(ShopLocation? location) {
    emit(ShopLocationState(
      status: ShopLocationStatus.restored,
      location: location,
    ));
  }

  /// Drops the picked location (registration/profile field left empty).
  void clear() => emit(const ShopLocationState());

  ShopLocationState _success(ShopLocation location) {
    return ShopLocationState(
      status: ShopLocationStatus.success,
      location: location,
      messageKey: 'locationPicked',
      messageSeverity: ShopLocationMessageSeverity.success,
    );
  }

  String _errorKey(ShopLocationFailure failure) {
    switch (failure) {
      case ShopLocationFailure.serviceDisabled:
        return 'locationServiceOff';
      case ShopLocationFailure.permissionDenied:
        return 'locationPermissionDenied';
      case ShopLocationFailure.permissionDeniedForever:
        return 'locationPermissionDeniedForever';
      case ShopLocationFailure.timeout:
        return 'locationTimeout';
      case ShopLocationFailure.failed:
        return 'locationFailed';
    }
  }
}
