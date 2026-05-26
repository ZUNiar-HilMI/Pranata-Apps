import 'package:shared_preferences/shared_preferences.dart';

/// Rate limiter untuk login.
/// Jika gagal login ≥ [maxAttempts] kali dalam [windowDuration],
/// pengguna diblokir selama [lockoutDuration].
class LoginRateLimiter {
  static const int maxAttempts = 6;
  static const Duration windowDuration = Duration(minutes: 1);
  static const Duration lockoutDuration = Duration(minutes: 5);

  static const String _attemptsKey = 'login_failed_attempts';
  static const String _lockoutUntilKey = 'login_lockout_until';

  // ── Singleton ──────────────────────────────────────────────────────────────
  LoginRateLimiter._();
  static final LoginRateLimiter _instance = LoginRateLimiter._();
  factory LoginRateLimiter() => _instance;

  // ── Cek apakah pengguna boleh mencoba login ────────────────────────────────
  Future<bool> canAttemptLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntilMs = prefs.getInt(_lockoutUntilKey);

    if (lockoutUntilMs != null) {
      final lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutUntilMs);
      if (DateTime.now().isBefore(lockoutUntil)) {
        return false; // masih dalam masa blokir
      } else {
        // Masa blokir sudah lewat, hapus data lockout
        await prefs.remove(_lockoutUntilKey);
        await prefs.remove(_attemptsKey);
      }
    }
    return true;
  }

  // ── Sisa waktu blokir dalam detik ──────────────────────────────────────────
  Future<int> getRemainingLockoutSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntilMs = prefs.getInt(_lockoutUntilKey);

    if (lockoutUntilMs == null) return 0;

    final lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutUntilMs);
    final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  // ── Catat percobaan login gagal ────────────────────────────────────────────
  Future<void> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();

    // Ambil daftar timestamp percobaan gagal
    final attemptsRaw = prefs.getStringList(_attemptsKey) ?? [];
    final now = DateTime.now();

    // Tambahkan timestamp baru
    attemptsRaw.add(now.millisecondsSinceEpoch.toString());

    // Hapus percobaan yang sudah di luar window (lebih dari 1 menit lalu)
    final windowStart = now.subtract(windowDuration);
    final recentAttempts = attemptsRaw.where((ts) {
      final t = DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
      return t.isAfter(windowStart);
    }).toList();

    // Simpan kembali
    await prefs.setStringList(_attemptsKey, recentAttempts);

    // Cek apakah sudah melewati batas
    if (recentAttempts.length >= maxAttempts) {
      // Blokir selama lockoutDuration
      final lockoutUntil = now.add(lockoutDuration);
      await prefs.setInt(
        _lockoutUntilKey,
        lockoutUntil.millisecondsSinceEpoch,
      );
    }
  }

  // ── Reset setelah login berhasil ───────────────────────────────────────────
  Future<void> resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey);
    await prefs.remove(_lockoutUntilKey);
  }
}
