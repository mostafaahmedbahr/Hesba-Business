import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hesba/core/utils/toast.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;
  BuildContext? _context;

  bool get isConnected => _isConnected;

  void initialize(BuildContext context) {
    _context = context;
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final wasConnected = _isConnected;
      _isConnected = result != ConnectivityResult.none;

      if (_context == null || !_context!.mounted) return;

      if (wasConnected && !_isConnected) {
        AppToast.error(_context!, 'لا يوجد اتصال بالإنترنت');
      } else if (!wasConnected && _isConnected) {
        AppToast.success(_context!, 'تم الاتصال بالإنترنت');
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _context = null;
  }
}
