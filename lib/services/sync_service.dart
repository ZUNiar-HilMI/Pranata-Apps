import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'storage_service.dart';
import '../models/activity.dart';

enum OperationType { saveActivity, updateActivity, deleteActivity }

class PendingOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      PendingOperation(
        id: json['id'],
        type: OperationType.values.firstWhere((e) => e.name == json['type']),
        data: Map<String, dynamic>.from(json['data']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _pendingKey = 'pending_operations';
  final ConnectivityService _connectivity = ConnectivityService();
  final StorageService _storage = StorageService();

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  /// Initialize: listen for connectivity and sync when online
  Future<void> initialize() async {
    await _updatePendingCount();
    _connectivity.connectivityStream.listen((isConnected) {
      if (isConnected) {
        syncPendingOperations();
      }
    });
  }

  /// Queue an activity save operation when offline
  Future<void> addPendingOperation(
    OperationType type,
    Map<String, dynamic> data,
  ) async {
    final op = PendingOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pendingKey) ?? [];
    existing.add(jsonEncode(op.toJson()));
    await prefs.setStringList(_pendingKey, existing);
    _pendingCount = existing.length;
    debugPrint('📋 Queued operation: ${type.name} (total: $_pendingCount)');
  }

  /// Sync all pending operations to storage
  Future<int> syncPendingOperations() async {
    if (!_connectivity.isConnected) return 0;

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey) ?? [];
    if (pending.isEmpty) return 0;

    debugPrint('🔄 Syncing ${pending.length} pending operation(s)...');
    int synced = 0;
    final failed = <String>[];

    for (final opJson in pending) {
      try {
        final op = PendingOperation.fromJson(jsonDecode(opJson));
        await _executeOperation(op);
        synced++;
      } catch (e) {
        debugPrint('❌ Failed to sync operation: $e');
        failed.add(opJson);
      }
    }

    // Keep only failed operations
    await prefs.setStringList(_pendingKey, failed);
    _pendingCount = failed.length;
    debugPrint('✅ Synced $synced operation(s), ${failed.length} failed');
    return synced;
  }

  /// Save activity — uses offline queue if not connected
  Future<void> saveActivity(Activity activity) async {
    if (_connectivity.isConnected) {
      await _storage.saveActivity(activity);
    } else {
      // Save locally immediately for UI
      await _storage.saveActivity(activity);
      // Queue for future sync
      await addPendingOperation(
        OperationType.saveActivity,
        activity.toJson(),
      );
    }
  }

  /// Update activity — uses offline queue if not connected
  Future<void> updateActivity(Activity activity) async {
    if (_connectivity.isConnected) {
      await _storage.updateActivity(activity);
    } else {
      await _storage.updateActivity(activity);
      await addPendingOperation(
        OperationType.updateActivity,
        activity.toJson(),
      );
    }
  }

  Future<void> _executeOperation(PendingOperation op) async {
    switch (op.type) {
      case OperationType.saveActivity:
        final activity = Activity.fromJson(op.data);
        await _storage.saveActivity(activity);
        break;
      case OperationType.updateActivity:
        final activity = Activity.fromJson(op.data);
        await _storage.updateActivity(activity);
        break;
      case OperationType.deleteActivity:
        await _storage.deleteActivity(op.data['id']);
        break;
    }
  }

  Future<void> _updatePendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    _pendingCount = (prefs.getStringList(_pendingKey) ?? []).length;
  }

  Future<void> clearPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
    _pendingCount = 0;
  }
}
