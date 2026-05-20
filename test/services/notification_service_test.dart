import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/services/notification_service.dart';
// avoid importing FirestoreService to prevent Firebase initialization
import 'package:my_first_app/models/activity.dart';

class FakeFirestoreService {
  final StreamController<List<Activity>> controller = StreamController<List<Activity>>.broadcast();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService realtime badge', () {
    test('badge decrements immediately when notifications read', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
      });

      // Ensure the last-read timestamp is set far in the past so activities
      // created now are considered unread.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notif_last_read_testuser', DateTime(2000).millisecondsSinceEpoch);

      final fake = FakeFirestoreService();
      NotificationService().setActivitiesStreamForTesting(({userId, dinasId}) => fake.controller.stream);

      final activity = Activity(
        id: 'a1',
        name: 'Test',
        description: 'desc',
        budget: 0.0,
        date: DateTime.now(),
        location: 'loc',
        userId: 'testuser',
        dinasId: 'd1',
        status: 'approved',
        createdAt: DateTime.now(),
      );

      // Collect emitted values so we can assert order (1 then 0) without
      // depending on exact intermediate emissions.
      final emitted = <int>[];
      final sub = NotificationService()
          .getUnreadCountStream(userId: 'testuser', isAdmin: false)
          .listen((v) => emitted.add(v));

      // Act: publish activities (unread -> should eventually contain 1)
      await Future.delayed(const Duration(milliseconds: 200));
      fake.controller.add([activity]);
      await Future.delayed(const Duration(milliseconds: 200));

      // Ensure we saw an unread count of 1 at some point
      expect(emitted.contains(1), isTrue, reason: 'Expected unread count to include 1');

      // Act: mark as read and expect eventual 0
      await NotificationService().markNotificationsRead('testuser');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(emitted.contains(0), isTrue, reason: 'Expected unread count to include 0 after marking read');

      // Ensure 1 occurred before 0
      final i1 = emitted.indexOf(1);
      final i0 = emitted.indexOf(0);
      expect(i1 >= 0 && i0 >= 0 && i1 < i0, isTrue,
          reason: 'Expected 1 to appear before 0 in emitted stream');

      await sub.cancel();
      await fake.controller.close();
    });
  });
}
