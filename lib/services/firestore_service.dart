import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import '../models/dinas.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'api_data_service.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final ApiDataService _apiData = ApiDataService();

  static const String _activitiesCollection = 'activities';
  static const String _dinasCollection = 'dinas';

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVITIES
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Get Activities ───────────────────────────────────────────────────────
  /// [dinasId] → null = ambil semua (superadmin), isi = filter per dinas
  Future<List<Activity>> getActivities({String? dinasId}) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.getActivities(dinasId: dinasId);
    }

    try {
      Query<Map<String, dynamic>> query = _db.collection(_activitiesCollection);
      if (dinasId != null) {
        query = query.where('dinasId', isEqualTo: dinasId);
      } else {
        query = query.orderBy('createdAt', descending: true);
      }
      final snapshot = await query.get();
      final list = snapshot.docs.map((doc) => _docToActivity(doc)).toList();
      if (dinasId != null) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  // ─── Get Activities by User ───────────────────────────────────────────────
  Future<List<Activity>> getActivitiesByUser(String userId) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.getActivitiesByUser(userId);
    }

    try {
      final snapshot = await _db
          .collection(_activitiesCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final list = snapshot.docs.map((doc) => _docToActivity(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      return [];
    }
  }

  // ─── Save Activity ────────────────────────────────────────────────────────
  Future<void> saveActivity(Activity activity) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.saveActivity(activity);
    }

    await _db
        .collection(_activitiesCollection)
        .doc(activity.id)
        .set(_activityToMap(activity));
  }

  // ─── Update Activity ──────────────────────────────────────────────────────
  Future<void> updateActivity(Activity activity) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.updateActivity(activity);
    }

    await _db
        .collection(_activitiesCollection)
        .doc(activity.id)
        .update(_activityToMap(activity));
  }

  // ─── Delete Activity ──────────────────────────────────────────────────────
  Future<void> deleteActivity(String id) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.deleteActivity(id);
    }

    await _db.collection(_activitiesCollection).doc(id).delete();
  }

  // ─── Get by ID ────────────────────────────────────────────────────────────
  Future<Activity?> getActivityById(String id) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.getActivityById(id);
    }

    final doc = await _db.collection(_activitiesCollection).doc(id).get();
    if (!doc.exists) return null;
    return _docToActivity(doc);
  }

  // ─── Update Status ────────────────────────────────────────────────────────
  /// Admin dinas panggil ini untuk approve/reject kegiatan di dinasnya.
  Future<void> updateActivityStatus(String id, String newStatus) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.updateActivityStatus(id, newStatus);
    }

    await _db
        .collection(_activitiesCollection)
        .doc(id)
        .update({'status': newStatus});
  }

  // ─── Statistics ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStatistics({
    String? userId,
    String? dinasId,
    int? year,
  }) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.getStatistics(userId: userId, dinasId: dinasId, year: year);
    }

    List<Activity> activities;
    if (userId != null) {
      activities = await getActivitiesByUser(userId);
    } else {
      activities = await getActivities(dinasId: dinasId);
    }

    final filtered = year != null
        ? activities.where((a) => a.date.year == year).toList()
        : activities;

    final totalBudget = filtered.fold<double>(0, (acc, a) => acc + a.budget);

    return {
      'totalActivities': filtered.length,
      'totalBudget': totalBudget,
      'pendingActivities': filtered.where((a) => a.status == 'pending').length,
      'approvedActivities': filtered.where((a) => a.status == 'approved').length,
    };
  }

  Future<double> getTotalBudgetLimit({String? dinasId}) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.getTotalBudgetLimit(dinasId: dinasId);
    }

    final docId = dinasId != null ? 'budget_$dinasId' : 'budget';
    final doc = await _db.collection('settings').doc(docId).get();
    if (doc.exists) {
      return (doc.data()?['limit'] as num?)?.toDouble() ?? 1000000000.0;
    }
    return 1000000000.0;
  }

  Future<void> setTotalBudgetLimit(double amount, {String? dinasId}) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.setTotalBudgetLimit(amount, dinasId: dinasId);
    }

    final docId = dinasId != null ? 'budget_$dinasId' : 'budget';
    await _db.collection('settings').doc(docId).set({'limit': amount});
  }

  Future<List<double>> getMonthlyBudget({
    String? userId,
    String? dinasId,
    required int year,
  }) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.getMonthlyBudget(userId: userId, dinasId: dinasId, year: year);
    }

    final activities = userId != null
        ? await getActivitiesByUser(userId)
        : await getActivities(dinasId: dinasId);

    final yearActivities = activities.where((a) => a.date.year == year).toList();
    final monthlyBudgets = List<double>.filled(12, 0.0);
    for (var a in yearActivities) {
      monthlyBudgets[a.date.month - 1] += a.budget;
    }
    return monthlyBudgets;
  }

  // ─── Real-time stream ─────────────────────────────────────────────────────
  /// [dinasId] → null = semua dinas (superadmin), isi = filter per dinas
  Stream<List<Activity>> activitiesStream({String? userId, String? dinasId}) {
    if (ApiConfig.useCustomBackend) {
      return _apiData.activitiesStream(userId: userId, dinasId: dinasId);
    }

    if (userId != null) {
      return _db
          .collection(_activitiesCollection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => _docToActivity(doc)).toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });
    } else if (dinasId != null) {
      return _db
          .collection(_activitiesCollection)
          .where('dinasId', isEqualTo: dinasId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => _docToActivity(doc)).toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });
    } else {
      return _db
          .collection(_activitiesCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => _docToActivity(doc)).toList());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DINAS CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ambil semua dinas (realtime stream)
  Stream<List<Dinas>> dinasStream() {
    if (ApiConfig.useCustomBackend) {
      return _apiData.dinasStream().map((list) {
        DinasTheme.setLoadedDinas(list);
        return list;
      });
    }

    return _db
        .collection(_dinasCollection)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => Dinas.fromDocument(doc)).toList();
          DinasTheme.setLoadedDinas(list);
          return list;
        });
  }

  /// Ambil semua dinas (one-time)
  Future<List<Dinas>> getDinasList() async {
    if (ApiConfig.useCustomBackend) {
      final list = await _apiData.getDinasList();
      DinasTheme.setLoadedDinas(list);
      return list;
    }

    final snapshot = await _db.collection(_dinasCollection).get();
    final list = snapshot.docs.map((doc) => Dinas.fromDocument(doc)).toList();
    DinasTheme.setLoadedDinas(list);
    return list;
  }

  /// Buat dinas baru (hanya superadmin)
  Future<void> createDinas(Dinas dinas) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.createDinas(dinas);
    }

    await _db.collection(_dinasCollection).doc(dinas.id).set({
      'name': dinas.name,
      'code': dinas.code,
      'description': dinas.description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update dinas
  Future<void> updateDinas(Dinas dinas) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.updateDinas(dinas);
    }

    await _db.collection(_dinasCollection).doc(dinas.id).update({
      'name': dinas.name,
      'code': dinas.code,
      'description': dinas.description,
    });
  }

  /// Hapus dinas (hanya superadmin, dengan konfirmasi)
  Future<void> deleteDinas(String dinasId) async {
    if (ApiConfig.useCustomBackend) {
      return _apiData.deleteDinas(dinasId);
    }

    await _db.collection(_dinasCollection).doc(dinasId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Activity _docToActivity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      budget: (data['budget'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] as String,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      photoBefore: data['photoBefore'] as String?,
      photoAfter: data['photoAfter'] as String?,
      userId: data['userId'] as String,
      dinasId: data['dinasId'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _activityToMap(Activity a) {
    return {
      'name': a.name,
      'description': a.description,
      'budget': a.budget,
      'date': Timestamp.fromDate(a.date),
      'location': a.location,
      'latitude': a.latitude,
      'longitude': a.longitude,
      'photoBefore': a.photoBefore,
      'photoAfter': a.photoAfter,
      'userId': a.userId,
      'dinasId': a.dinasId,
      'status': a.status,
      'createdAt': a.createdAt == DateTime(0)
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(a.createdAt),
    };
  }
}
