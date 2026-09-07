import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/utils/toast.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final InternetConnection _connection = InternetConnection();
  StreamSubscription<InternetStatus>? _subscription;
  bool _isConnected = true;
  BuildContext? _context;

  bool get isConnected => _isConnected;

  void initialize(BuildContext context) {
    _context = context;

    _connection.onStatusChange.listen((status) {
      final wasConnected = _isConnected;
      _isConnected = status == InternetStatus.connected;

      if (_context == null || !_context!.mounted) return;

      if (wasConnected && !_isConnected) {
        AppToast.error(_context!, 'connectivityLost'.tr());
      } else if (!wasConnected && _isConnected) {
        AppToast.success(_context!, 'connectivityRestored'.tr());
      }
    });
  }

  Future<bool> checkConnection() async {
    _isConnected = await _connection.hasInternetAccess;
    return _isConnected;
  }

  void dispose() {
    _subscription?.cancel();
    _context = null;
  }
}
