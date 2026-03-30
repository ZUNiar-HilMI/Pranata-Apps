import '../../lib/models/user.dart';
import '../../lib/models/activity.dart';

/// Test data factories and helpers

class TestData {
  // Sample Users
  static User createTestUser({
    String id = 'test-user-1',
    String username = 'testuser',
    String email = 'test@example.com',
    String password = 'password123',
    String fullName = 'Test User',
    String role = 'member',
    bool isEmailVerified = true,
  }) {
    return User(
      id: id,
      username: username,
      email: email,
      password: User.hashPassword(password),
      fullName: fullName,
      role: role,
      isEmailVerified: isEmailVerified,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  static User createAdminUser() {
    return createTestUser(
      id: 'admin-1',
      username: 'admin',
      email: 'admin@example.com',
      fullName: 'Admin User',
      role: 'admin',
    );
  }

  // Sample Activities
  static Activity createTestActivity({
    String id = 'activity-1',
    String name = 'Test Activity',
    String description = 'Test Description',
    double budget = 1000000,
    DateTime? date,
    String location = 'Test Location',
    double? latitude = -6.2088,
    double? longitude = 106.8456,
    String? photoBefore,
    String? photoAfter,
    String userId = 'test-user-1',
    String status = 'pending',
  }) {
    return Activity(
      id: id,
      name: name,
      description: description,
      budget: budget,
      date: date ?? DateTime(2024, 1, 15),
      location: location,
      latitude: latitude,
      longitude: longitude,
      photoBefore: photoBefore,
      photoAfter: photoAfter,
      userId: userId,
      status: status,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  static Activity createApprovedActivity() {
    return createTestActivity(
      id: 'activity-approved',
      name: 'Approved Activity',
      status: 'approved',
    );
  }

  static Activity createRejectedActivity() {
    return createTestActivity(
      id: 'activity-rejected',
      name: 'Rejected Activity',
      status: 'rejected',
    );
  }

  // Helper methods
  static List<User> createMultipleUsers(int count) {
    return List.generate(
      count,
      (index) => createTestUser(
        id: 'user-$index',
        username: 'user$index',
        email: 'user$index@example.com',
        fullName: 'User $index',
      ),
    );
  }

  static List<Activity> createMultipleActivities(int count, String userId) {
    return List.generate(
      count,
      (index) => createTestActivity(
        id: 'activity-$index',
        name: 'Activity $index',
        budget: 1000000.0 * (index + 1),
        userId: userId,
      ),
    );
  }
}
