import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool _isConnected = true;

  bool get isConnected => _isConnected;
  Stream<bool> get connectivityStream => _controller.stream;

  /// Call this once during app startup (in main.dart)
  Future<void> initialize() async {
    // Check current status
    final result = await _connectivity.checkConnectivity();
    _isConnected = _isOnline(result);

    // Listen for changes
    _connectivity.onConnectivityChanged.listen((result) {
      final wasConnected = _isConnected;
      _isConnected = _isOnline(result);

      if (wasConnected != _isConnected) {
        _controller.add(_isConnected);
        debugPrint(_isConnected ? '✅ Back online' : '📴 Gone offline');
      }
    });
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  void dispose() {
    _controller.close();
  }
}
