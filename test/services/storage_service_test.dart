import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/storage_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('StorageService Tests', () {
    late StorageService storageService;

    setUp(() async {
      // Initialize with empty preferences before each test
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    tearDown(() async {
      // Clean up after each test
      await storageService.clearAllActivities();
    });

    test('getActivities should return empty list initially', () async {
      final activities = await storageService.getActivities();
      
      expect(activities, isEmpty);
    });

    test('saveActivity should store activity', () async {
      final activity = TestData.createTestActivity();
      
      await storageService.saveActivity(activity);
      
      final activities = await storageService.getActivities();
      expect(activities.length, equals(1));
      expect(activities.first.id, equals(activity.id));
    });

    test('saveActivity should store multiple activities', () async {
      final activity1 = TestData.createTestActivity(id: 'act-1', name: 'Activity 1');
      final activity2 = TestData.createTestActivity(id: 'act-2', name: 'Activity 2');
      
      await storageService.saveActivity(activity1);
      await storageService.saveActivity(activity2);
      
      final activities = await storageService.getActivities();
      expect(activities.length, equals(2));
    });

    test('getActivityById should return correct activity', () async {
      final activity = TestData.createTestActivity(id: 'test-123');
      await storageService.saveActivity(activity);
      
      final retrieved = await storageService.getActivityById('test-123');
      
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test-123'));
      expect(retrieved.name, equals(activity.name));
    });

    test('getActivityById should return null for non-existent id', () async {
      final retrieved = await storageService.getActivityById('non-existent');
      
      expect(retrieved, isNull);
    });

    test('updateActivity should modify existing activity', () async {
      final original = TestData.createTestActivity(
        id: 'update-test',
        name: 'Original Name',
        status: 'pending',
      );
      await storageService.saveActivity(original);
      
      final updated = original.copyWith(
        name: 'Updated Name',
        status: 'approved',
      );
      await storageService.updateActivity(updated);
      
      final retrieved = await storageService.getActivityById('update-test');
      expect(retrieved!.name, equals('Updated Name'));
      expect(retrieved.status, equals('approved'));
    });

    test('deleteActivity should remove activity', () async {
      final activity = TestData.createTestActivity(id: 'delete-test');
      await storageService.saveActivity(activity);
      
      await storageService.deleteActivity('delete-test');
      
      final retrieved = await storageService.getActivityById('delete-test');
      expect(retrieved, isNull);
    });

    test('getActivitiesByUser should filter by userId', () async {
      final user1Activity = TestData.createTestActivity(
        id: 'act-1',
        userId: 'user-1',
      );
      final user2Activity = TestData.createTestActivity(
        id: 'act-2',
        userId: 'user-2',
      );
      
      await storageService.saveActivity(user1Activity);
      await storageService.saveActivity(user2Activity);
      
      final user1Activities = await storageService.getActivitiesByUser('user-1');
      
      expect(user1Activities.length, equals(1));
      expect(user1Activities.first.userId, equals('user-1'));
    });

    test('getStatistics should calculate total activities', () async {
      final activities = TestData.createMultipleActivities(3, 'user-1');
      for (var activity in activities) {
        await storageService.saveActivity(activity);
      }
      
      final stats = await storageService.getStatistics();
      
      expect(stats['totalActivities'], equals(3));
    });

    test('getStatistics should calculate total budget', () async {
      await storageService.saveActivity(
        TestData.createTestActivity(id: 'act-1', budget: 1000000),
      );
      await storageService.saveActivity(
        TestData.createTestActivity(id: 'act-2', budget: 2000000),
      );
      
      final stats = await storageService.getStatistics();
      
      expect(stats['totalBudget'], equals(3000000.0));
    });

    test('getStatistics should count pending activities', () async {
      await storageService.saveActivity(
        TestData.createTestActivity(id: 'act-1', status: 'pending'),
      );
      await storageService.saveActivity(
        TestData.createTestActivity(id: 'act-2', status: 'approved'),
      );
      await storageService.saveActivity(
        TestData.createTestActivity(id: 'act-3', status: 'pending'),
      );
      
      final stats = await storageService.getStatistics();
      
      expect(stats['pendingActivities'], equals(2));
    });

    test('getStatistics should count approved activities', () async {
      await storageService.saveActivity(
        TestData.createTestActivity(id: 'act-1', status: 'approved'),
      );
      await storageService.saveActivity(
        TestData.createTestActivity(id: 'act-2', status: 'approved'),
      );
      await storageService.saveActivity(
        TestData.createTestActivity(id: 'act-3', status: 'rejected'),
      );
      
      final stats = await storageService.getStatistics();
      
      expect(stats['approvedActivities'], equals(2));
    });

    test('getStatistics should filter by userId when provided', () async {
      await storageService.saveActivity(
        TestData.createTestActivity(id: 'act-1', userId: 'user-1'),
      );
      await storageService.saveActivity(
        TestData.createTestActivity(id: 'act-2', userId: 'user-2'),
      );
      
      final stats = await storageService.getStatistics(userId: 'user-1');
      
      expect(stats['totalActivities'], equals(1));
    });

    test('getStatistics should filter by year when provided', () async {
      await storageService.saveActivity(
        TestData.createTestActivity(
          id: 'act-1',
          date: DateTime(2024, 1, 15),
        ),
      );
      await storageService.saveActivity(
        TestData.createTestActivity(
          id: 'act-2',
          date: DateTime(2023, 5, 10),
        ),
      );
      
      final stats = await storageService.getStatistics(year: 2024);
      
      expect(stats['totalActivities'], equals(1));
    });

    test('getTotalBudgetLimit should return default 1 billion', () async {
      final limit = await storageService.getTotalBudgetLimit();
      
      expect(limit, equals(1000000000.0));
    });

    test('setTotalBudgetLimit should update budget limit', () async {
      await storageService.setTotalBudgetLimit(500000000.0);
      
      final limit = await storageService.getTotalBudgetLimit();
      
      expect(limit, equals(500000000.0));
    });

    test('getMonthlyBudget should return 12 months of data', () async {
      final monthlyBudgets = await storageService.getMonthlyBudget(year: 2024);
      
      expect(monthlyBudgets.length, equals(12));
    });

    test('getMonthlyBudget should calculate correctly per month', () async {
      // January activity
      await storageService.saveActivity(
        TestData.createTestActivity(
          id: 'jan-1',
          date: DateTime(2024, 1, 15),
          budget: 1000000,
        ),
      );
      // February activity
      await storageService.saveActivity(
        TestData.createTestActivity(
          id: 'feb-1',
          date: DateTime(2024, 2, 10),
          budget: 2000000,
        ),
      );
      
      final monthlyBudgets = await storageService.getMonthlyBudget(year: 2024);
      
      expect(monthlyBudgets[0], equals(1000000.0)); // January (index 0)
      expect(monthlyBudgets[1], equals(2000000.0)); // February (index 1)
      expect(monthlyBudgets[2], equals(0.0)); // March (index 2)
    });

    test('clearAllActivities should remove all activities', () async {
      final activities = TestData.createMultipleActivities(5, 'user-1');
      for (var activity in activities) {
        await storageService.saveActivity(activity);
      }
      
      await storageService.clearAllActivities();
      
      final remaining = await storageService.getActivities();
      expect(remaining, isEmpty);
    });
  });
}
