/// Smart Waste Sorting — App Constants
/// API key, system prompt Gemini, data kategori sampah, dan string UI.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi utama aplikasi.
class AppConstants {
  AppConstants._(); // Prevent instantiation

  // ─────────────────────────────────────────────
  // API Configuration
  // ─────────────────────────────────────────────

  /// API Key Google Gemini — Dimuat dari file .env
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_API_KEY_HERE';

  /// Model Gemini yang digunakan — Dimuat dari file .env (fallback: gemini-3.5-flash)
  static String get geminiModel => dotenv.env['GEMINI_MODEL'] ?? 'gemini-3.5-flash';

  // ─────────────────────────────────────────────
  // System Instruction — Prompt untuk Gemini AI
  // ─────────────────────────────────────────────

  /// System instruction yang dikirim ke Gemini untuk klasifikasi sampah.
  /// Mengarahkan AI untuk menganalisis gambar dan mengembalikan JSON terstruktur.
  static const String geminiSystemInstruction = '''
Kamu adalah asisten AI ahli klasifikasi sampah. Tugasmu adalah menganalisis gambar yang diberikan dan mengklasifikasikan jenis sampah ke dalam salah satu dari 3 kategori berikut:

1. **Organik** — Sampah yang berasal dari makhluk hidup dan dapat terurai secara alami. Contoh: sisa makanan, daun, kulit buah, sayuran busuk, nasi basi, tulang, cangkang telur.

2. **Anorganik** — Sampah yang tidak mudah terurai secara alami dan memerlukan waktu sangat lama untuk terdekomposisi. Contoh: plastik, kaca, kaleng, kertas, kardus, botol, styrofoam, kain, karet.

3. **B3** (Bahan Berbahaya dan Beracun) — Sampah yang mengandung zat berbahaya dan dapat mencemari lingkungan serta membahayakan kesehatan. Contoh: baterai, lampu neon, elektronik rusak, obat kedaluwarsa, cat, pestisida, jarum suntik, oli bekas.

ATURAN PENTING:
- Analisis gambar dengan teliti.
- Jika gambar BUKAN sampah atau tidak jelas, tetap berikan estimasi terbaik berdasarkan objek yang terlihat.
- Confidence harus realistis (0-100). Jika gambar blur atau ambigu, turunkan confidence.
- SELALU jawab dalam format JSON yang valid, tanpa teks tambahan di luar JSON.
- Semua teks dalam Bahasa Indonesia.

FORMAT RESPONSE (JSON saja, tanpa markdown code block):
{
  "category": "Organik" atau "Anorganik" atau "B3",
  "confidence": 85,
  "item_name": "Nama item yang terdeteksi",
  "description": "Deskripsi singkat tentang item dan mengapa masuk kategori ini (2-3 kalimat).",
  "disposal_tips": "Cara pembuangan yang benar untuk item ini (2-3 kalimat).",
  "environmental_impact": "Dampak lingkungan jika item ini tidak dibuang dengan benar (2-3 kalimat).",
  "fun_fact": "Fakta menarik tentang item ini atau kategorinya (1-2 kalimat)."
}
''';

  // ─────────────────────────────────────────────
  // Waste Category Data — Seed data untuk tabel categories
  // ─────────────────────────────────────────────

  /// Data seed untuk tabel `categories` di SQLite.
  static const List<Map<String, String>> wasteCategorySeedData = [
    {
      'name': 'Organik',
      'color_hex': '#4CAF50',
      'icon_name': 'eco',
      'description':
          'Sampah yang berasal dari makhluk hidup dan dapat terurai secara alami oleh mikroorganisme. Contoh: sisa makanan, daun kering, kulit buah, sayuran, nasi, tulang ayam, dan cangkang telur.',
      'disposal_guide':
          'Pisahkan ke tempat sampah berwarna HIJAU. Sampah organik dapat diolah menjadi kompos atau pupuk organik. Hindari mencampur dengan sampah anorganik atau B3.',
    },
    {
      'name': 'Anorganik',
      'color_hex': '#2196F3',
      'icon_name': 'delete_outline',
      'description':
          'Sampah yang tidak mudah terurai secara alami dan memerlukan waktu puluhan hingga ratusan tahun untuk terdekomposisi. Contoh: plastik, botol kaca, kaleng aluminium, kertas, kardus, styrofoam, dan kain.',
      'disposal_guide':
          'Pisahkan ke tempat sampah berwarna BIRU. Bersihkan sampah dari sisa makanan sebelum dibuang. Bawa ke bank sampah untuk didaur ulang. Kurangi penggunaan plastik sekali pakai.',
    },
    {
      'name': 'B3',
      'color_hex': '#F44336',
      'icon_name': 'warning_amber',
      'description':
          'Bahan Berbahaya dan Beracun (B3) yang dapat mencemari lingkungan dan membahayakan kesehatan manusia. Contoh: baterai, lampu neon, elektronik rusak, obat kedaluwarsa, cat, pestisida, dan jarum suntik.',
      'disposal_guide':
          'JANGAN buang ke tempat sampah biasa. Kumpulkan secara terpisah dan serahkan ke fasilitas pengolahan limbah B3 atau drop-off point khusus yang disediakan pemerintah daerah.',
    },
  ];

  // ─────────────────────────────────────────────
  // App Strings — Bahasa Indonesia
  // ─────────────────────────────────────────────

  static const String appName = 'Smart Waste Sorting';
  static const String appTagline = 'Klasifikasi Cerdas Jenis Sampah';

  // Home Screen
  static const String homeGreeting = 'Halo! 👋';
  static const String homeSubtitle = 'Yuk, kelola sampahmu dengan cerdas';
  static const String homeScanCta = 'Scan Sampahmu';
  static const String homeRecentScans = 'Scan Terakhir';
  static const String homeCategories = 'Kategori Sampah';
  static const String homeNoScans = 'Belum ada riwayat scan';

  // Scan Screen
  static const String scanTitle = 'Scan Sampah';
  static const String scanFromCamera = 'Ambil dari Kamera';
  static const String scanFromGallery = 'Pilih dari Galeri';
  static const String scanAnalyzing = 'Menganalisis gambar...';
  static const String scanInstruction = 'Pilih gambar sampah untuk dianalisis oleh AI';

  // Result Screen
  static const String resultTitle = 'Hasil Klasifikasi';
  static const String resultScanAgain = 'Scan Lagi';
  static const String resultSave = 'Simpan';
  static const String resultDescription = 'Deskripsi';
  static const String resultDisposalTips = 'Tips Pembuangan';
  static const String resultEnvironmentalImpact = 'Dampak Lingkungan';
  static const String resultFunFact = 'Fakta Menarik';

  // History Screen
  static const String historyTitle = 'Riwayat Scan';
  static const String historyEmpty = 'Belum ada riwayat scan.\nMulai scan pertamamu!';
  static const String historySearchHint = 'Cari item...';
  static const String historyDeleteConfirm = 'Hapus riwayat ini?';

  // Statistics Screen
  static const String statsTitle = 'Statistik';
  static const String statsTotalScans = 'Total Scan';
  static const String statsTopCategory = 'Kategori Terbanyak';
  static const String statsDistribution = 'Distribusi Kategori';
  static const String statsWeekly = 'Scan Mingguan';
  static const String statsEcoScore = 'Eco Score';

  // Navigation
  static const String navHome = 'Beranda';
  static const String navScan = 'Scan';
  static const String navHistory = 'Riwayat';
  static const String navStats = 'Statistik';

  // Onboarding
  static const String onboardingSkip = 'Lewati';
  static const String onboardingNext = 'Lanjut';
  static const String onboardingGetStarted = 'Mulai Sekarang';
  static const String onboardingTitle1 = 'Kenali Sampahmu';
  static const String onboardingDesc1 =
      'Pelajari jenis-jenis sampah: Organik, Anorganik, dan B3. Pemilahan yang benar dimulai dari pengetahuan.';
  static const String onboardingTitle2 = 'Foto & Klasifikasi';
  static const String onboardingDesc2 =
      'Cukup foto sampahmu, AI kami akan mengklasifikasikan jenisnya secara otomatis dalam hitungan detik.';
  static const String onboardingTitle3 = 'Kelola Lebih Baik';
  static const String onboardingDesc3 =
      'Dapatkan tips pembuangan yang tepat dan lihat dampak positifmu terhadap lingkungan.';

  // Errors
  static const String errorGeneral = 'Terjadi kesalahan. Silakan coba lagi.';
  static const String errorNoImage = 'Tidak ada gambar yang dipilih.';
  static const String errorAiFailed = 'Gagal menganalisis gambar. Periksa koneksi internet Anda.';
  static const String errorApiKey = 'API key belum dikonfigurasi.';

  // SharedPreferences Keys
  static const String prefOnboardingComplete = 'onboarding_complete';
}
