import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

/// Manages notification badge counts for members and admins.
///
/// - **Member**: counts activities whose status changed (approved/rejected)
///   after the last time the member opened the notifications screen.
/// - **Admin**: counts pending activities in their dinas.
class NotificationService {
  static const _prefix = 'notif_last_read_';
  FirestoreService? _firestore;
  final StreamController<String> _lastReadChangeController = StreamController<String>.broadcast();
  Stream<List<dynamic>> Function({String? userId, String? dinasId})? _activitiesStreamProvider;

  // ── Singleton ──────────────────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ── Get last-read timestamp ────────────────────────────────────────────────
  Future<DateTime> _getLastReadTimestamp(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('$_prefix$userId');
    if (ms == null) return DateTime(2000); // never read → show all
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // ── Mark notifications as read ─────────────────────────────────────────────
  Future<void> markNotificationsRead(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_prefix$userId',
      DateTime.now().millisecondsSinceEpoch,
    );
    // Notify listeners so unread count streams can update immediately
    try {
      _lastReadChangeController.add(userId);
    } catch (_) {}
  }

  // ── Unread count stream ────────────────────────────────────────────────────
  /// Returns a real-time stream of the number of unread notifications.
  ///
  /// Jika user menonaktifkan notifikasi di Settings, selalu mengembalikan 0.
  ///
  /// For **admin**: count of pending activities in their dinas.
  /// For **member**: count of approved/rejected activities created after
  ///                 the last time they opened the notifications screen.
  Stream<int> getUnreadCountStream({
    required String userId,
    required bool isAdmin,
    String? dinasId,
  }) async* {
    // Cek apakah notifikasi diizinkan oleh pengguna di Settings
    final prefs = await SharedPreferences.getInstance();
    final notifEnabled = prefs.getBool('notifications_enabled') ?? true;
    if (!notifEnabled) {
      yield 0;
      return;
    }

    if (isAdmin) {
      // Admin: count pending activities in their dinas
            yield* (_activitiesStreamProvider?.call(dinasId: dinasId) ??
              (_firestore ??= FirestoreService()).activitiesStream(dinasId: dinasId))
        .map((activities) =>
          activities.where((a) => a.status == 'pending').length);
    } else {
      // Member: we need to react both to Firestore activity changes AND
      // to local "last read" updates (when user opens notifications).
      // Strategy: listen to activities stream and also a local controller
      // that emits when markNotificationsRead() is called. Cache the latest
      // activities snapshot and recompute when either source fires.
      final controller = StreamController<int>();

      List activitiesCache = [];
      StreamSubscription? activitiesSub;
      StreamSubscription? lastReadSub;

      Future<void> recompute() async {
        // Check if notifications still enabled
        final prefs2 = await SharedPreferences.getInstance();
        final still = prefs2.getBool('notifications_enabled') ?? true;
        if (!still) {
          if (!controller.isClosed) controller.add(0);
          return;
        }

        final lastRead = await _getLastReadTimestamp(userId);
        final count = activitiesCache
            .where((a) =>
                (a.status == 'approved' || a.status == 'rejected') &&
                (a.createdAt is DateTime ? a.createdAt.isAfter(lastRead) : DateTime.parse(a.createdAt.toString()).isAfter(lastRead)))
            .length;
        
        if (!controller.isClosed) controller.add(count);
      }

            activitiesSub = (_activitiesStreamProvider?.call(userId: userId) ??
              (_firestore ??= FirestoreService()).activitiesStream(userId: userId))
          .listen((acts) {
        activitiesCache = acts;
        recompute();
      });

      lastReadSub = _lastReadChangeController.stream.where((id) => id == userId).listen((_) {
        recompute();
      });

      // When consumer cancels, clean up
      controller.onCancel = () async {
        await activitiesSub?.cancel();
        await lastReadSub?.cancel();
        await controller.close();
      };

      yield* controller.stream;
    }
  }

  // Ensure controller closed when service disposed (app exit)
  void dispose() {
    try {
      _lastReadChangeController.close();
    } catch (_) {}
  }

  /// Testing helper: replace the Firestore service with a fake/mock.
  @visibleForTesting
  void setFirestoreForTesting(FirestoreService fs) {
    _firestore = fs;
  }

  /// Testing helper: inject a custom activities stream provider to avoid
  /// initializing Firestore in unit tests.
  @visibleForTesting
  void setActivitiesStreamForTesting(Stream<List<dynamic>> Function({String? userId, String? dinasId}) provider) {
    _activitiesStreamProvider = provider;
  }
}
