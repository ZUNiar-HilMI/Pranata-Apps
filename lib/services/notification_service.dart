import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

/// Manages notification badge counts for members and admins.
///
/// - **Member**: counts activities whose status changed (approved/rejected)
///   after the last time the member opened the notifications screen.
/// - **Admin**: counts pending activities in their dinas.
class NotificationService {
  static const _prefix = 'notif_last_read_';
  final FirestoreService _firestore = FirestoreService();

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
  }

  // ── Unread count stream ────────────────────────────────────────────────────
  /// Returns a real-time stream of the number of unread notifications.
  ///
  /// For **admin**: count of pending activities in their dinas.
  /// For **member**: count of approved/rejected activities created after
  ///                 the last time they opened the notifications screen.
  Stream<int> getUnreadCountStream({
    required String userId,
    required bool isAdmin,
    String? dinasId,
  }) {
    if (isAdmin) {
      // Admin: count pending activities in their dinas
      return _firestore
          .activitiesStream(dinasId: dinasId)
          .map((activities) =>
              activities.where((a) => a.status == 'pending').length);
    } else {
      // Member: count activities with approved/rejected status
      // that were created after their last read timestamp.
      return _firestore
          .activitiesStream(userId: userId)
          .asyncMap((activities) async {
        final lastRead = await _getLastReadTimestamp(userId);
        return activities
            .where((a) =>
                (a.status == 'approved' || a.status == 'rejected') &&
                a.createdAt.isAfter(lastRead))
            .length;
      });
    }
  }
}
