import 'dart:async';
import '../models/activity.dart';
import '../models/dinas.dart';
import 'api_client.dart';

class ApiDataService {
  final ApiClient _client = ApiClient();

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVITIES CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Get Activities ───────────────────────────────────────────────────────
  Future<List<Activity>> getActivities({String? dinasId}) async {
    final queryParams = <String>[];
    if (dinasId != null) queryParams.add('dinasId=$dinasId');

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.join('&')}'
        : '';
    final response = await _client.get('/activities$queryString');

    if (response == null) return [];
    final list = response as List;
    return list.map((a) => _mapToActivity(a as Map<String, dynamic>)).toList();
  }

  // ─── Get Activities by User ───────────────────────────────────────────────
  Future<List<Activity>> getActivitiesByUser(String userId) async {
    // In our backend, GET /activities automatically filters by role/userId for MEMBERS
    final response = await _client.get('/activities');
    if (response == null) return [];
    final list = response as List;
    return list.map((a) => _mapToActivity(a as Map<String, dynamic>)).toList();
  }

  // ─── Save Activity ────────────────────────────────────────────────────────
  Future<void> saveActivity(Activity activity) async {
    await _client.post('/activities', {
      'name': activity.name,
      'description': activity.description,
      'budget': activity.budget,
      'date': activity.date.toIso8601String(),
      'location': activity.location,
      'latitude': activity.latitude,
      'longitude': activity.longitude,
      'photoBefore': activity.photoBefore,
      'photoAfter': activity.photoAfter,
    });
  }

  // ─── Update Activity ──────────────────────────────────────────────────────
  Future<void> updateActivity(Activity activity) async {
    await _client.patch('/activities/${activity.id}', {
      'name': activity.name,
      'description': activity.description,
      'budget': activity.budget,
      'date': activity.date.toIso8601String(),
      'location': activity.location,
      'latitude': activity.latitude,
      'longitude': activity.longitude,
      'photoBefore': activity.photoBefore,
      'photoAfter': activity.photoAfter,
    });
  }

  // ─── Delete Activity ──────────────────────────────────────────────────────
  Future<void> deleteActivity(String id) async {
    await _client.delete('/activities/$id');
  }

  // ─── Get by ID ────────────────────────────────────────────────────────────
  Future<Activity?> getActivityById(String id) async {
    final response = await _client.get('/activities/$id');
    if (response == null) return null;
    return _mapToActivity(response as Map<String, dynamic>);
  }

  // ─── Update Status ────────────────────────────────────────────────────────
  Future<void> updateActivityStatus(String id, String newStatus) async {
    await _client.patch('/activities/$id/status', {
      'status': newStatus.toUpperCase(),
    });
  }

  // ─── Statistics ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStatistics({
    String? userId,
    String? dinasId,
    int? year,
  }) async {
    final queryParams = <String>[];
    if (year != null) queryParams.add('year=$year');

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.join('&')}'
        : '';
    final response = await _client.get('/activities/statistics$queryString');

    if (response == null) {
      return {
        'totalActivities': 0,
        'totalBudget': 0.0,
        'pendingActivities': 0,
        'approvedActivities': 0,
      };
    }

    return {
      'totalActivities': response['counts']['total'] as int,
      'totalBudget': (response['totalSpent'] as num).toDouble(),
      'pendingActivities': response['counts']['pending'] as int,
      'approvedActivities': response['counts']['approved'] as int,
    };
  }

  // ─── Budget Limit ─────────────────────────────────────────────────────────
  Future<double> getTotalBudgetLimit({String? dinasId}) async {
    final queryString = dinasId == null ? '' : '?dinasId=$dinasId';
    final response = await _client.get('/settings/budget-limit$queryString');
    if (response == null) return 1000000000.0;
    return double.parse(response['value'] as String);
  }

  Future<void> setTotalBudgetLimit(double amount, {String? dinasId}) async {
    final queryString = dinasId == null ? '' : '?dinasId=$dinasId';
    await _client.put('/settings/budget-limit$queryString', {
      'value': amount.toString(),
    });
  }

  // ─── Monthly Budget ───────────────────────────────────────────────────────
  Future<List<double>> getMonthlyBudget({
    String? userId,
    String? dinasId,
    required int year,
  }) async {
    final activities = await getActivities(dinasId: dinasId);
    final yearActivities = activities
        .where((a) => a.date.year == year)
        .toList();
    final monthlyBudgets = List<double>.filled(12, 0.0);

    for (var a in yearActivities) {
      monthlyBudgets[a.date.month - 1] += a.budget;
    }
    return monthlyBudgets;
  }

  // ─── Real-time Streams (Periodic Polling Wrapper) ─────────────────────────

  Stream<List<Activity>> activitiesStream({String? userId, String? dinasId}) {
    late StreamController<List<Activity>> controller;
    Timer? timer;

    void fetchAndPush() async {
      try {
        final list = await getActivities(dinasId: dinasId);
        if (!controller.isClosed) {
          controller.add(list);
        }
      } catch (_) {
        // Suppress errors during stream polling
      }
    }

    controller = StreamController<List<Activity>>(
      onListen: () {
        fetchAndPush();
        timer = Timer.periodic(
          const Duration(seconds: 4),
          (_) => fetchAndPush(),
        );
      },
      onCancel: () {
        timer?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DINAS CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ambil semua dinas (realtime stream via polling)
  Stream<List<Dinas>> dinasStream() {
    late StreamController<List<Dinas>> controller;
    Timer? timer;

    void fetchAndPush() async {
      try {
        final list = await getDinasList();
        if (!controller.isClosed) {
          controller.add(list);
        }
      } catch (_) {
        // Suppress stream errors
      }
    }

    controller = StreamController<List<Dinas>>(
      onListen: () {
        fetchAndPush();
        timer = Timer.periodic(
          const Duration(seconds: 6),
          (_) => fetchAndPush(),
        );
      },
      onCancel: () {
        timer?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  /// Ambil semua dinas (one-time)
  Future<List<Dinas>> getDinasList() async {
    final response = await _client.get('/dinas');
    if (response == null) return [];
    final list = response as List;
    return list.map((d) => _mapToDinas(d as Map<String, dynamic>)).toList();
  }

  /// Buat dinas baru (hanya superadmin)
  Future<void> createDinas(Dinas dinas) async {
    await _client.post('/dinas', {
      'name': dinas.name,
      'code': dinas.code,
      'description': dinas.description,
    });
  }

  /// Update dinas
  Future<void> updateDinas(Dinas dinas) async {
    await _client.patch('/dinas/${dinas.id}', {
      'name': dinas.name,
      'code': dinas.code,
      'description': dinas.description,
    });
  }

  /// Hapus dinas (hanya superadmin)
  Future<void> deleteDinas(String dinasId) async {
    await _client.delete('/dinas/$dinasId');
  }

  // ─── Private Helpers / Mappers ────────────────────────────────────────────

  Activity _mapToActivity(Map<String, dynamic> data) {
    return Activity(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      budget: (data['budget'] as num).toDouble(),
      date: DateTime.parse(data['date'] as String),
      location: data['location'] as String,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      photoBefore: data['photoBefore'] as String?,
      photoAfter: data['photoAfter'] as String?,
      userId: data['userId'] as String,
      dinasId: data['dinasId'] as String? ?? '',
      status: (data['status'] as String? ?? 'pending').toLowerCase(),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Dinas _mapToDinas(Map<String, dynamic> data) {
    return Dinas(
      id: data['id'] as String,
      name: data['name'] as String,
      code: data['code'] as String,
      description: data['description'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
