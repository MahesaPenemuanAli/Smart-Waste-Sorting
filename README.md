# Smart Waste Sorting

Smart Waste Sorting adalah aplikasi Flutter untuk membantu pengguna mengklasifikasikan jenis sampah secara cerdas menggunakan teknologi Artificial Intelligence dan Computer Vision. Aplikasi ini dapat menganalisis gambar sampah dari kamera atau galeri, lalu mengelompokkannya ke dalam kategori Organik, Anorganik, atau B3.

Aplikasi ini dibuat untuk mendukung kebiasaan memilah sampah dengan lebih mudah, cepat, dan edukatif melalui informasi hasil klasifikasi, tips pembuangan, dampak lingkungan, serta riwayat scan pengguna.

## Fitur Utama

- Klasifikasi sampah berbasis gambar menggunakan AI
- Input gambar melalui kamera atau galeri
- Live scan menggunakan kamera
- Kategori sampah:
  - Organik
  - Anorganik
  - B3
- Menampilkan confidence hasil klasifikasi
- Menampilkan deskripsi jenis sampah
- Menampilkan tips pembuangan yang benar
- Menampilkan dampak lingkungan
- Menampilkan fakta menarik tentang sampah
- Riwayat hasil scan
- Statistik scan pengguna
- Sistem login dan register lokal
- Penyimpanan data lokal menggunakan SQLite
- Tampilan dark theme modern
- Onboarding untuk pengguna baru

## Teknologi yang Digunakan

### 1. Flutter

Flutter digunakan sebagai framework utama untuk membangun aplikasi mobile secara cross-platform. Dengan Flutter, aplikasi dapat dikembangkan untuk Android, iOS, Web, Windows, Linux, dan macOS dari satu basis kode.

### 2. Dart

Dart digunakan sebagai bahasa pemrograman utama dalam pengembangan aplikasi Flutter ini.

### 3. Google Gemini AI

Google Gemini AI digunakan sebagai teknologi Artificial Intelligence untuk menganalisis gambar sampah. Gambar yang dipilih pengguna dikirim ke Gemini, kemudian AI mengembalikan hasil klasifikasi dalam format JSON.

Output AI meliputi:

- Kategori sampah
- Confidence
- Nama objek
- Deskripsi
- Tips pembuangan
- Dampak lingkungan
- Fakta menarik

Package yang digunakan:

```yaml
google_generative_ai
````

### 4. Computer Vision

Computer Vision digunakan untuk menganalisis gambar sampah. Pada aplikasi ini, proses computer vision dilakukan melalui layanan Gemini AI, sehingga aplikasi tidak menggunakan model machine learning lokal seperti TensorFlow Lite.

### 5. Image Picker

Image Picker digunakan untuk mengambil gambar dari kamera atau memilih gambar dari galeri.

Package yang digunakan:

```yaml
image_picker
```

### 6. Camera

Package camera digunakan untuk fitur live camera preview dan live scan.

Package yang digunakan:

```yaml
camera
```

### 7. Provider

Provider digunakan sebagai state management untuk mengatur perubahan data aplikasi, seperti status scan, hasil klasifikasi, autentikasi pengguna, riwayat scan, dan statistik.

Package yang digunakan:

```yaml
provider
```

### 8. SQLite / Sqflite

SQLite digunakan sebagai database lokal untuk menyimpan data aplikasi secara offline di perangkat pengguna.

Data yang disimpan meliputi:

* Kategori sampah
* Hasil scan
* Data pengguna
* Riwayat klasifikasi

Package yang digunakan:

```yaml
sqflite
```

### 9. Shared Preferences

Shared Preferences digunakan untuk menyimpan data sederhana seperti status onboarding dan session login pengguna.

Package yang digunakan:

```yaml
shared_preferences
```

### 10. Crypto

Crypto digunakan untuk hashing password pengguna sebelum disimpan ke database lokal.

Package yang digunakan:

```yaml
crypto
```

### 11. Flutter Dotenv

Flutter Dotenv digunakan untuk menyimpan konfigurasi penting seperti API key Gemini agar tidak ditulis langsung di dalam kode.

Package yang digunakan:

```yaml
flutter_dotenv
```

### 12. FL Chart

FL Chart digunakan untuk menampilkan statistik dalam bentuk grafik, seperti distribusi kategori sampah dan jumlah scan mingguan.

Package yang digunakan:

```yaml
fl_chart
```

### 13. Lottie

Lottie digunakan untuk menampilkan animasi pada aplikasi agar tampilan lebih menarik dan interaktif.

Package yang digunakan:

```yaml
lottie
```

### 14. Google Fonts

Google Fonts digunakan untuk mempercantik tampilan teks pada aplikasi.

Package yang digunakan:

```yaml
google_fonts
```

### 15. Shimmer

Shimmer digunakan untuk memberikan efek loading skeleton saat data sedang dimuat.

Package yang digunakan:

```yaml
shimmer
```

### 16. Intl

Intl digunakan untuk format tanggal dan lokalisasi Bahasa Indonesia.

Package yang digunakan:

```yaml
intl
```

## Struktur Folder

```txt
lib/
├── config/
│   ├── constants.dart
│   └── theme.dart
│
├── models/
│   ├── category.dart
│   ├── scan_result.dart
│   └── user.dart
│
├── providers/
│   ├── auth_provider.dart
│   └── scan_provider.dart
│
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── scan_screen.dart
│   ├── live_scan_screen.dart
│   ├── result_screen.dart
│   ├── multi_result_screen.dart
│   ├── history_screen.dart
│   ├── statistics_screen.dart
│   └── profile_screen.dart
│
├── services/
│   ├── database_service.dart
│   └── gemini_service.dart
│
├── app.dart
└── main.dart
```

## Alur Kerja Aplikasi

1. Pengguna membuka aplikasi.
2. Aplikasi menampilkan onboarding untuk pengguna baru.
3. Pengguna dapat login atau register.
4. Pengguna memilih gambar sampah dari kamera atau galeri.
5. Gambar dikirim ke Gemini AI untuk dianalisis.
6. AI mengembalikan hasil klasifikasi dalam format JSON.
7. Aplikasi menampilkan hasil klasifikasi.
8. Hasil scan disimpan ke database lokal.
9. Pengguna dapat melihat riwayat dan statistik hasil scan.

## Kategori Sampah

### Organik

Sampah yang berasal dari makhluk hidup dan dapat terurai secara alami.

Contoh:

* Sisa makanan
* Daun
* Kulit buah
* Sayuran busuk
* Tulang
* Cangkang telur

### Anorganik

Sampah yang tidak mudah terurai secara alami dan biasanya dapat didaur ulang.

Contoh:

* Plastik
* Botol
* Kaca
* Kaleng
* Kardus
* Styrofoam
* Kain

### B3

Bahan Berbahaya dan Beracun yang dapat mencemari lingkungan atau membahayakan kesehatan.

Contoh:

* Baterai
* Lampu neon
* Elektronik rusak
* Obat kedaluwarsa
* Cat
* Pestisida
* Jarum suntik
* Oli bekas

## Instalasi dan Menjalankan Project

### 1. Clone Repository

```bash
git clone https://github.com/MahesaPenemuanAli/Smart-Waste-Sorting.git
cd Smart-Waste-Sorting
```

### 2. Install Dependency

```bash
flutter pub get
```

### 3. Buat File `.env`

Buat file `.env` di root project, lalu isi dengan konfigurasi berikut:

```env
GEMINI_API_KEY=masukkan_api_key_gemini_anda
GEMINI_MODEL=gemini-3.5-flash
```

### 4. Jalankan Aplikasi

```bash
flutter run
```

## Permission

Aplikasi membutuhkan permission kamera dan akses galeri untuk mengambil gambar sampah yang akan dianalisis.

## Catatan Pengembangan

* Aplikasi ini menggunakan Gemini AI sebagai mesin klasifikasi gambar.
* Database yang digunakan masih lokal menggunakan SQLite.
* Sistem login dan register masih berbasis penyimpanan lokal.
* Aplikasi membutuhkan koneksi internet saat melakukan klasifikasi gambar menggunakan Gemini AI.
* API key disimpan melalui file `.env` agar lebih aman dan mudah dikonfigurasi.

## Kelebihan Aplikasi

* Mudah digunakan oleh pengguna umum
* Membantu edukasi pemilahan sampah
* Menggunakan AI untuk klasifikasi gambar
* Memiliki riwayat dan statistik scan
* Tampilan modern dan responsif
* Dapat dikembangkan menjadi aplikasi lingkungan berbasis SDGs

## Potensi Pengembangan Selanjutnya

* Integrasi dengan lokasi bank sampah terdekat
* Rekomendasi drop-off point berdasarkan lokasi pengguna
* Sistem poin atau eco score yang lebih lengkap
* Integrasi backend online
* Dashboard admin berbasis web
* Model machine learning lokal agar dapat berjalan offline
* Scan barcode produk untuk mengetahui jenis kemasan
* Edukasi daur ulang berdasarkan jenis sampah

## Kontributor

MahesaPenemuanAli

## Lisensi

Project ini dibuat untuk kebutuhan pembelajaran dan pengembangan aplikasi berbasis Flutter, AI, dan pengelolaan sampah cerdas.

```

Catatan penting: teknologi AI di project ini lebih tepat disebut **Gemini AI / Computer Vision berbasis API**, bukan machine learning lokal, karena klasifikasi gambarnya dilakukan melalui layanan Gemini, bukan model yang ditanam langsung di aplikasi.
```
