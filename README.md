# 📋 PRANATA - Proses Anggaran lan Tata Data

<p align="center">
  <img src="assets/images/app_icon.png" alt="PRANATA Logo" width="120"/>
</p>

<p align="center">
  <strong>Aplikasi pengelolaan aktivitas dan anggaran berbasis mobile</strong><br>
  Dibangun dengan Flutter & Firebase
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android"/>
</p>

---

## 📖 Tentang Aplikasi

**PRANATA** (*Proses Anggaran lan Tata Data*) adalah aplikasi mobile yang dirancang untuk membantu pengelolaan data aktivitas dan anggaran pada instansi pemerintahan (dinas). Aplikasi ini mendukung **multi-dinas** dengan tema visual yang berbeda untuk setiap dinas, serta memiliki sistem **role-based access control** (SuperAdmin, Admin, dan Member).

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔐 **Autentikasi** | Login & registrasi dengan Firebase Auth, verifikasi OTP via email |
| 👥 **Manajemen Role** | Tiga level akses: SuperAdmin, Admin Dinas, dan Member |
| 📝 **Input Aktivitas** | Pencatatan kegiatan lengkap dengan foto, lokasi GPS, dan anggaran |
| 📊 **Laporan** | Laporan aktivitas per bulan dengan filter dan ringkasan |
| 📤 **Ekspor Data** | Ekspor laporan ke format **Excel** dan **PDF** |
| 📍 **Geolokasi** | Pencatatan lokasi otomatis menggunakan GPS dengan peta interaktif |
| 📷 **Kamera & Galeri** | Pengambilan foto langsung dari kamera atau galeri |
| 🔔 **Notifikasi** | Sistem notifikasi untuk verifikasi dan pembaruan status |
| 🎨 **Multi-Dinas Theme** | Tema warna unik untuk setiap dinas |
| 🌐 **Offline Support** | Sinkronisasi data saat koneksi tidak stabil |

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Backend:** [Firebase](https://firebase.google.com/)
  - Firebase Authentication
  - Cloud Firestore
- **Image Storage:** [Cloudinary](https://cloudinary.com/)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Maps:** [flutter_map](https://pub.dev/packages/flutter_map) + [latlong2](https://pub.dev/packages/latlong2)
- **Location:** [Geolocator](https://pub.dev/packages/geolocator) + [Geocoding](https://pub.dev/packages/geocoding)
- **Export:** [excel](https://pub.dev/packages/excel) (Excel) + [pdf](https://pub.dev/packages/pdf) (PDF)

---

## 📂 Struktur Proyek

```
lib/
├── main.dart                 # Entry point aplikasi
├── firebase_options.dart     # Konfigurasi Firebase
├── config/
│   ├── app_theme.dart        # Tema aplikasi & dinas themes
│   ├── cloudinary_config.dart
│   └── email_config.dart
├── models/
│   ├── activity.dart         # Model aktivitas
│   ├── dinas.dart            # Model dinas
│   └── user.dart             # Model pengguna
├── providers/
│   └── auth_provider.dart    # State management autentikasi
├── screens/
│   ├── welcome_screen.dart   # Halaman selamat datang
│   ├── login_screen.dart     # Halaman login
│   ├── register_screen.dart  # Halaman registrasi
│   ├── home_screen.dart      # Dashboard utama
│   ├── add_activity_screen.dart
│   ├── reports_screen.dart   # Laporan & ekspor
│   ├── profile_screen.dart
│   ├── settings_screen.dart
│   ├── notifications_screen.dart
│   └── superadmin/           # Panel Super Admin
├── services/
│   ├── firebase_auth_service.dart
│   ├── firestore_service.dart
│   ├── export_service.dart   # Logika ekspor Excel & PDF
│   ├── image_service.dart
│   ├── cloudinary_service.dart
│   ├── connectivity_service.dart
│   ├── sync_service.dart
│   └── ...
└── widgets/
```

---

## 🚀 Cara Menjalankan

### Prasyarat

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.10)
- [Android Studio](https://developer.android.com/studio) atau [VS Code](https://code.visualstudio.com/)
- Akun [Firebase](https://console.firebase.google.com/)
- Akun [Cloudinary](https://cloudinary.com/) (untuk upload gambar)

### Langkah-Langkah

1. **Clone repository**
   ```bash
   git clone https://github.com/ZUNiar-HilMI/Pranata-Apps.git
   cd Pranata-Apps
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Firebase**
   - Buat project di [Firebase Console](https://console.firebase.google.com/)
   - Aktifkan **Authentication** (Email/Password)
   - Aktifkan **Cloud Firestore**
   - Download `google-services.json` dan letakkan di `android/app/`
   - Update file `lib/firebase_options.dart` sesuai konfigurasi

4. **Konfigurasi Cloudinary**
   - Buat akun di [Cloudinary](https://cloudinary.com/)
   - Update konfigurasi di `lib/config/cloudinary_config.dart`

5. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

---

## 👤 Role & Hak Akses

| Role | Hak Akses |
|------|-----------|
| **SuperAdmin** | Kelola semua dinas, dashboard khusus, manajemen pengguna global |
| **Admin Dinas** | Verifikasi anggota, ekspor laporan, kelola aktivitas dinas |
| **Member** | Input aktivitas, lihat laporan pribadi |

---

## 📱 Screenshots

> *Coming soon* — Screenshots akan ditambahkan setelah rilis.

---

## 👨‍💻 Developer

| | |
|---|---|
| **Nama** | Zuniar Hilmi |
| **GitHub** | [@ZUNiar-HilMI](https://github.com/ZUNiar-HilMI) |
| **Email** | zuniarhilmi10@gmail.com |

---

## 📄 Lisensi

Proyek ini bersifat **private** dan dikembangkan untuk keperluan magang / internal instansi.

---

<p align="center">
  Dibuat dengan ❤️ menggunakan Flutter
</p>
