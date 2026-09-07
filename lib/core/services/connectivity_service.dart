import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/material.dart';
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
        AppToast.error(_context!, 'لا يوجد اتصال بالإنترنت');
      } else if (!wasConnected && _isConnected) {
        AppToast.success(_context!, 'تم الاتصال بالإنترنت');
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
