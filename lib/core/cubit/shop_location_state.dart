import 'package:equatable/equatable.dart';

import '../models/shop_location.dart';

enum ShopLocationStatus {
  /// Nothing picked yet.
  idle,

  /// GPS fix in flight.
  locating,

  /// Converting coordinates ↔ address in flight.
  geocoding,

  /// A location was picked during this session (toast-worthy).
  success,

  /// A location restored from the stored profile (silent).
  restored,

  /// Permission/GPS/geocoding failure — see [messageKey].
  failure,
}

enum ShopLocationMessageSeverity { success, warning, error }

/// State of the shared shop-location picker (registration + profile edit).
///
/// [messageKey] is a translation key (same convention as the subscription
/// feature): the UI translates it right before showing it.
class ShopLocationState extends Equatable {
  const ShopLocationState({
    this.status = ShopLocationStatus.idle,
    this.location,
    this.messageKey,
    this.messageSeverity,
  });

  final ShopLocationStatus status;
  final ShopLocation? location;

  /// Translation key of the last toast/notice (`location*` keys).
  final String? messageKey;

  final ShopLocationMessageSeverity? messageSeverity;

  bool get hasLocation => location != null && location!.hasAnyData;

  bool get isBusy =>
      status == ShopLocationStatus.locating ||
      status == ShopLocationStatus.geocoding;

  ShopLocationState copyWith({
    ShopLocationStatus? status,
    ShopLocation? location,
    bool clearLocation = false,
    String? messageKey,
    ShopLocationMessageSeverity? messageSeverity,
    bool clearMessage = false,
  }) {
    return ShopLocationState(
      status: status ?? this.status,
      location: clearLocation ? null : (location ?? this.location),
      messageKey: clearMessage ? null : (messageKey ?? this.messageKey),
      messageSeverity:
          clearMessage ? null : (messageSeverity ?? this.messageSeverity),
    );
  }

  @override
  List<Object?> get props => [status, location, messageKey, messageSeverity];
}
