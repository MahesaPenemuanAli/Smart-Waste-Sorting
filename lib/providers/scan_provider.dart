/// Smart Waste Sorting — Scan Provider
/// State management untuk proses scan, riwayat, dan statistik.
/// Menghubungkan GeminiService dan DatabaseService dengan UI layer.
library;

import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/category.dart';
import '../models/scan_result.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';

/// Status proses scan.
enum ScanStatus {
  idle,       // Menunggu input
  picking,    // Memilih gambar
  analyzing,  // Mengirim ke Gemini AI
  success,    // Berhasil
  error,      // Gagal
}

/// Provider utama untuk mengelola state aplikasi.
class ScanProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _imagePicker = ImagePicker();

  // ─────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────

  ScanStatus _status = ScanStatus.idle;
  ScanStatus get status => _status;

  /// File gambar yang sedang dipilih/di-scan.
  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  /// Hasil scan terakhir.
  ScanResult? _currentResult;
  ScanResult? get currentResult => _currentResult;

  /// Daftar riwayat scan.
  List<ScanResult> _scanHistory = [];
  List<ScanResult> get scanHistory => _scanHistory;

  /// Daftar kategori (dari database).
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  /// Pesan error.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Statistik.
  int _totalScans = 0;
  int get totalScans => _totalScans;

  int _todayScans = 0;
  int get todayScans => _todayScans;

  String? _topCategory;
  String? get topCategory => _topCategory;

  Map<String, int> _categoryDistribution = {};
  Map<String, int> get categoryDistribution => _categoryDistribution;

  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> get weeklyData => _weeklyData;

  double _averageConfidence = 0.0;
  double get averageConfidence => _averageConfidence;

  /// Apakah Gemini sudah diinisialisasi.
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ─────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────

  /// Inisialisasi provider — load kategori dan statistik.
  /// Gemini akan auto-initialize saat pertama kali scan.
  Future<void> initialize({String? apiKey}) async {
    try {
      // Coba inisialisasi Gemini (jika API key valid)
      try {
        _geminiService.initialize(apiKey: apiKey);
      } catch (e) {
        // API key belum valid — tidak apa-apa, akan retry saat scan
        debugPrint('Gemini init skipped: $e');
      }

      // Load kategori dari database (ini harus selalu berhasil)
      _categories = await _dbService.getAllCategories();

      // Load statistik awal
      await refreshStats();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isInitialized = true; // Tetap tandai initialized agar tidak loop
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Image Picking
  // ─────────────────────────────────────────────

  /// Pilih gambar dari kamera.
  Future<void> pickImageFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  /// Pilih gambar dari galeri.
  Future<void> pickImageFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  /// Internal — pilih gambar dari sumber tertentu.
  Future<void> _pickImage(ImageSource source) async {
    try {
      _status = ScanStatus.picking;
      _errorMessage = null;
      notifyListeners();

      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) {
        // User membatalkan
        _status = ScanStatus.idle;
        notifyListeners();
        return;
      }

      _selectedImage = File(picked.path);
      _status = ScanStatus.idle;
      notifyListeners();
    } catch (e) {
      _status = ScanStatus.error;
      _errorMessage = 'Gagal memilih gambar: $e';
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Scanning (Gemini AI Classification)
  // ─────────────────────────────────────────────

  /// Scan gambar yang sudah dipilih — kirim ke Gemini, parse, simpan.
  Future<void> scanSelectedImage() async {
    if (_selectedImage == null) {
      _errorMessage = 'Tidak ada gambar yang dipilih.';
      _status = ScanStatus.error;
      notifyListeners();
      return;
    }

    await _performScan(_selectedImage!);
  }

  /// Pick + scan dalam satu langkah — dari kamera.
  Future<void> scanFromCamera() async {
    await _pickImage(ImageSource.camera);
    if (_selectedImage != null) {
      await _performScan(_selectedImage!);
    }
  }

  /// Pick + scan dalam satu langkah — dari galeri.
  Future<void> scanFromGallery() async {
    await _pickImage(ImageSource.gallery);
    if (_selectedImage != null) {
      await _performScan(_selectedImage!);
    }
  }

  /// Scan dari file langsung (digunakan oleh Live Scan / Crop).
  Future<void> scanFromFile(File imageFile) async {
    _selectedImage = imageFile;
    notifyListeners();
    await _performScan(imageFile);
  }

  /// Classify image only — untuk live preview (TIDAK simpan ke DB).
  Future<Map<String, dynamic>?> classifyImageOnly(File imageFile) async {
    try {
      final result = await _geminiService.classifyWaste(imageFile);
      return {
        'parsedData': result.parsedData,
        'rawResponse': result.rawResponse,
      };
    } catch (e) {
      debugPrint('Error in classifyImageOnly: $e');
      return null;
    }
  }

  /// Simpan hasil live classification ke database.
  Future<bool> saveLiveClassification({
    required Map<String, dynamic> parsedData,
    required String rawResponse,
    required File imageFile,
  }) async {
    try {
      final categoryName = (parsedData['category'] as String?) ?? '';
      final category = await _dbService.getCategoryByName(categoryName);
      if (category == null) return false;

      final savedPath = await _saveImageToAppDir(imageFile);
      final scanResult = ScanResult.fromAiResponse(
        jsonMap: parsedData,
        imagePath: savedPath,
        categoryId: category.id!,
        rawResponse: rawResponse,
      );
      await _dbService.insertScanResult(scanResult);
      await refreshStats();
      await loadHistory();
      return true;
    } catch (e) {
      debugPrint('Error in saveLiveClassification: $e');
      return false;
    }
  }

  /// Internal — proses scan gambar.
  Future<void> _performScan(File imageFile) async {
    try {
      _status = ScanStatus.analyzing;
      _errorMessage = null;
      _currentResult = null;
      notifyListeners();

      // 1. Kirim ke Gemini AI
      final aiResult = await _geminiService.classifyWaste(imageFile);

      // 2. Resolve category ID dari nama kategori
      final categoryName = aiResult.category;
      final category = await _dbService.getCategoryByName(categoryName);

      if (category == null) {
        throw GeminiServiceException(
          'Kategori "$categoryName" tidak ditemukan di database.',
        );
      }

      // 3. Simpan gambar ke app directory (persistent)
      final savedPath = await _saveImageToAppDir(imageFile);

      // 4. Buat ScanResult
      final scanResult = aiResult.toScanResult(
        imagePath: savedPath,
        categoryId: category.id!,
      );

      // 5. Simpan ke database
      final insertedId = await _dbService.insertScanResult(scanResult);

      // 6. Ambil kembali dari DB (dengan category JOIN) untuk data lengkap
      _currentResult = await _dbService.getScanResultById(insertedId);

      // 7. Refresh stats
      await refreshStats();

      _status = ScanStatus.success;
      notifyListeners();
    } on GeminiServiceException catch (e) {
      _status = ScanStatus.error;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _status = ScanStatus.error;
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
    }
  }

  /// Simpan file gambar ke application documents directory.
  /// Returns path file yang tersimpan.
  Future<String> _saveImageToAppDir(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final scanDir = Directory(p.join(appDir.path, 'scan_images'));

    if (!await scanDir.exists()) {
      await scanDir.create(recursive: true);
    }

    final fileName =
        'scan_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';
    final savedFile = await imageFile.copy(p.join(scanDir.path, fileName));
    return savedFile.path;
  }

  // ─────────────────────────────────────────────
  // History
  // ─────────────────────────────────────────────

  /// Load semua riwayat scan dari database.
  Future<void> loadHistory() async {
    try {
      _scanHistory = await _dbService.getAllScanResults();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat riwayat: $e';
      notifyListeners();
    }
  }

  /// Cari riwayat scan berdasarkan query.
  Future<void> searchHistory(String query) async {
    try {
      if (query.trim().isEmpty) {
        await loadHistory();
        return;
      }
      _scanHistory = await _dbService.searchScanResults(query);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal mencari: $e';
      notifyListeners();
    }
  }

  /// Filter riwayat berdasarkan kategori ID. Null = semua.
  Future<void> filterHistoryByCategory(int? categoryId) async {
    try {
      if (categoryId == null) {
        await loadHistory();
        return;
      }
      _scanHistory = await _dbService.getScanResultsByCategory(categoryId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memfilter: $e';
      notifyListeners();
    }
  }

  /// Hapus satu riwayat scan.
  Future<void> deleteScanResult(int id) async {
    try {
      await _dbService.deleteScanResult(id);
      _scanHistory.removeWhere((r) => r.id == id);
      await refreshStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menghapus: $e';
      notifyListeners();
    }
  }

  /// Hapus semua riwayat scan.
  Future<void> deleteAllScanResults() async {
    try {
      await _dbService.deleteAllScanResults();
      _scanHistory = [];
      await refreshStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menghapus semua: $e';
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Statistics
  // ─────────────────────────────────────────────

  /// Refresh semua statistik dari database.
  Future<void> refreshStats() async {
    try {
      _totalScans = await _dbService.getTotalScanCount();
      _todayScans = await _dbService.getTodayScanCount();
      _topCategory = await _dbService.getTopCategory();
      _categoryDistribution = await _dbService.getScanCountByCategory();
      _weeklyData = await _dbService.getWeeklyScanData();
      _averageConfidence = await _dbService.getAverageConfidence();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat statistik: $e';
      notifyListeners();
    }
  }

  /// Eco Score — gamification sederhana.
  /// Skor berdasarkan jumlah scan dan variasi kategori.
  int get ecoScore {
    if (_totalScans == 0) return 0;

    // Base score: 10 poin per scan (max 500)
    final baseScore = (_totalScans * 10).clamp(0, 500);

    // Bonus variasi: 100 poin jika semua 3 kategori pernah di-scan
    final categoriesScanned =
        _categoryDistribution.values.where((c) => c > 0).length;
    final varietyBonus = categoriesScanned * 100;

    // Bonus konsistensi: berdasarkan rata-rata confidence
    final confidenceBonus = (_averageConfidence * 3).round();

    return (baseScore + varietyBonus + confidenceBonus).clamp(0, 1000);
  }

  // ─────────────────────────────────────────────
  // Utility
  // ─────────────────────────────────────────────

  /// Reset state scan (untuk scan ulang).
  void resetScan() {
    _status = ScanStatus.idle;
    _selectedImage = null;
    _currentResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
