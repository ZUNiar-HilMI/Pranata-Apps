/// Sistem lokalisasi sederhana untuk PRANATA.
/// Mendukung Bahasa Indonesia dan English.
/// Gunakan [AppStrings.t(key, lang)] untuk mengambil teks.
class AppStrings {
  static const _id = 'Bahasa Indonesia';
  static const _en = 'English';

  static const Map<String, Map<String, String>> _strings = {
    // ── Settings Screen ──────────────────────────────────────────────────
    'settings': {_id: 'Pengaturan', _en: 'Settings'},
    'settings_subtitle': {_id: 'Preferensi Aplikasi', _en: 'App Preferences'},
    'section_general': {_id: 'Umum', _en: 'General'},
    'section_appearance': {_id: 'Tampilan', _en: 'Appearance'},
    'section_data': {_id: 'Data & Penyimpanan', _en: 'Data & Storage'},
    'section_about': {_id: 'Tentang', _en: 'About'},
    'notifications': {_id: 'Notifikasi', _en: 'Notifications'},
    'notif_on': {_id: 'Notifikasi aktif', _en: 'Notifications enabled'},
    'notif_off': {_id: 'Notifikasi dinonaktifkan', _en: 'Notifications disabled'},
    'dark_mode': {_id: 'Mode Gelap', _en: 'Dark Mode'},
    'dark_mode_on': {_id: 'Tema gelap aktif', _en: 'Dark theme active'},
    'dark_mode_off': {_id: 'Tema terang aktif', _en: 'Light theme active'},
    'language': {_id: 'Bahasa', _en: 'Language'},
    'language_sub': {_id: 'Pilih bahasa antarmuka', _en: 'Select interface language'},
    'font_size': {_id: 'Ukuran Font', _en: 'Font Size'},
    'font_size_sub': {_id: 'Sesuaikan ukuran teks', _en: 'Adjust text size'},
    'clear_cache': {_id: 'Hapus Cache', _en: 'Clear Cache'},
    'clear_cache_sub': {_id: 'Bebaskan ruang penyimpanan', _en: 'Free up storage space'},
    'clear_cache_confirm': {
      _id: 'Hapus semua data cache aplikasi? Ini tidak akan menghapus data akun, kegiatan, atau foto Anda.',
      _en: 'Clear all app cache data? This will not delete your account data, activities, or photos.',
    },
    'app_version': {_id: 'Versi Aplikasi', _en: 'App Version'},
    'cancel': {_id: 'Batal', _en: 'Cancel'},
    'delete': {_id: 'Hapus', _en: 'Delete'},
    'close': {_id: 'Tutup', _en: 'Close'},
    'cache_cleared': {_id: 'Cache berhasil dihapus', _en: 'Cache cleared successfully'},

    // ── Notifications Screen ─────────────────────────────────────────────
    'notif_screen_title': {_id: 'Notifikasi', _en: 'Notifications'},
    'notif_pending': {_id: 'Kegiatan menunggu verifikasi', _en: 'Activities awaiting verification'},
    'verify': {_id: 'Verifikasi', _en: 'Verify'},
    'refresh': {_id: 'Refresh', _en: 'Refresh'},
    'notif_empty_admin': {_id: 'Semua Bersih! 🎉', _en: 'All Clear! 🎉'},
    'notif_empty_member': {_id: 'Belum Ada Notifikasi', _en: 'No Notifications Yet'},
    'notif_empty_admin_sub': {
      _id: 'Tidak ada kegiatan yang menunggu verifikasi.',
      _en: 'No activities waiting for verification.',
    },
    'notif_empty_member_sub': {
      _id: 'Tambahkan kegiatan untuk mulai menerima notifikasi.',
      _en: 'Add an activity to start receiving notifications.',
    },
    'today': {_id: 'Hari Ini', _en: 'Today'},
    'yesterday': {_id: 'Kemarin', _en: 'Yesterday'},
    'older': {_id: 'Lebih Lama', _en: 'Older'},

    // ── Notification Detail Screen ───────────────────────────────────────
    'notif_detail_title': {_id: 'Detail Notifikasi', _en: 'Notification Detail'},
    'status_approved': {_id: 'Disetujui ✅', _en: 'Approved ✅'},
    'status_rejected': {_id: 'Ditolak ❌', _en: 'Rejected ❌'},
    'status_pending': {_id: 'Menunggu Verifikasi ⏳', _en: 'Awaiting Verification ⏳'},
    'field_description': {_id: 'Deskripsi', _en: 'Description'},
    'field_date': {_id: 'Tanggal Kegiatan', _en: 'Activity Date'},
    'field_budget': {_id: 'Anggaran', _en: 'Budget'},
    'field_location': {_id: 'Lokasi', _en: 'Location'},
    'field_gps': {_id: 'Koordinat GPS', _en: 'GPS Coordinates'},
    'field_no_desc': {_id: '(Tidak ada deskripsi)', _en: '(No description)'},
    'docs': {_id: 'DOKUMENTASI', _en: 'DOCUMENTATION'},
    'photo_before': {_id: 'Foto Sebelum', _en: 'Before Photo'},
    'photo_after': {_id: 'Foto Sesudah', _en: 'After Photo'},
    'created_at': {_id: 'Dibuat', _en: 'Created'},

    // ── Font Size Options ────────────────────────────────────────────────
    'font_small': {_id: 'Kecil', _en: 'Small'},
    'font_normal': {_id: 'Normal', _en: 'Normal'},
    'font_large': {_id: 'Besar', _en: 'Large'},
    'font_small_desc': {_id: '85% ukuran normal', _en: '85% of normal size'},
    'font_normal_desc': {_id: 'Ukuran default', _en: 'Default size'},
    'font_large_desc': {_id: '115% ukuran normal', _en: '115% of normal size'},
    'select_language': {_id: 'Pilih Bahasa', _en: 'Select Language'},
    'select_font': {_id: 'Ukuran Font', _en: 'Font Size'},
    'font_preview': {
      _id: 'Perubahan berlaku langsung di seluruh aplikasi',
      _en: 'Changes apply immediately across the app',
    },
  };

  /// Ambil teks berdasarkan [key] dan [lang].
  /// Fallback ke Bahasa Indonesia jika key/lang tidak ditemukan.
  static String t(String key, String lang) {
    return _strings[key]?[lang] ?? _strings[key]?[_id] ?? key;
  }

  /// Shorthand: ambil teks dengan lang default Indonesia
  static String id(String key) => t(key, _id);

  /// Shorthand: ambil teks dengan lang default English
  static String en(String key) => t(key, _en);
}
