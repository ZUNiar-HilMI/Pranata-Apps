import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

class StorageService {
  static const String _activitiesKey = 'activities';

  // Get all activities
  Future<List<Activity>> getActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = prefs.getStringList(_activitiesKey) ?? [];
      return activitiesJson
          .map((json) => Activity.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get activities by user ID
  Future<List<Activity>> getActivitiesByUser(String userId) async {
    final activities = await getActivities();
    return activities.where((a) => a.userId == userId).toList();
  }

  // Save activity
  Future<void> saveActivity(Activity activity) async {
    final activities = await getActivities();
    activities.add(activity);
    await _saveActivities(activities);
  }

  // Update activity
  Future<void> updateActivity(Activity activity) async {
    final activities = await getActivities();
    final index = activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      activities[index] = activity;
      await _saveActivities(activities);
    }
  }

  // Delete activity
  Future<void> deleteActivity(String id) async {
    final activities = await getActivities();
    activities.removeWhere((a) => a.id == id);
    await _saveActivities(activities);
  }

  // Get activity by ID
  Future<Activity?> getActivityById(String id) async {
    final activities = await getActivities();
    try {
      return activities.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Private method to save activities
  Future<void> _saveActivities(List<Activity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = activities.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_activitiesKey, activitiesJson);
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics({String? userId, int? year}) async {
    final activities = userId != null
        ? await getActivitiesByUser(userId)
        : await getActivities();

    // Filter by year if provided
    final filteredActivities = year != null
        ? activities.where((a) => a.date.year == year).toList()
        : activities;

    final totalActivities = filteredActivities.length;
    final totalBudget = filteredActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.budget,
    );
    final pendingActivities = filteredActivities.where((a) => a.status == 'pending').length;
    final approvedActivities = filteredActivities.where((a) => a.status == 'approved').length;

    return {
      'totalActivities': totalActivities,
      'totalBudget': totalBudget,
      'pendingActivities': pendingActivities,
      'approvedActivities': approvedActivities,
    };
  }


  // Update activity status (pending / approved / rejected)
  Future<void> updateActivityStatus(String id, String newStatus) async {
    final activities = await getActivities();
    final index = activities.indexWhere((a) => a.id == id);
    if (index != -1) {
      activities[index] = activities[index].copyWith(status: newStatus);
      await _saveActivities(activities);
    }
  }

  // Clear all activities (for testing/debugging)
  Future<void> clearAllActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activitiesKey);
  }

  // Get total budget limit (default 1 Billion IDR)
  Future<double> getTotalBudgetLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('total_budget_limit') ?? 1000000000.0;
  }

  // Set total budget limit
  Future<void> setTotalBudgetLimit(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_budget_limit', amount);
  }

  // Get monthly budget breakdown for a specific year
  Future<List<double>> getMonthlyBudget({String? userId, required int year}) async {
    final activities = userId != null
        ? await getActivitiesByUser(userId)
        : await getActivities();

    // Filter by year
    final yearActivities = activities.where((a) => a.date.year == year).toList();

    // Calculate budget for each month (1-12)
    final monthlyBudgets = List<double>.filled(12, 0.0);
    
    for (var activity in yearActivities) {
      final monthIndex = activity.date.month - 1; // 0-indexed
      monthlyBudgets[monthIndex] += activity.budget;
    }

    return monthlyBudgets;
  }
}
