/// Smart Waste Sorting — Gemini AI Service
/// Komunikasi dengan Google Gemini 1.5 Flash untuk klasifikasi sampah.
/// Mengirim gambar ke Gemini Vision dan menerima response JSON terstruktur.
library;

import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/constants.dart';
import '../models/scan_result.dart';

/// Service untuk berkomunikasi dengan Google Gemini AI.
/// Bertanggung jawab untuk mengirim gambar dan menerima klasifikasi sampah.
class GeminiService {
  GenerativeModel? _model;

  /// Singleton instance.
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  /// Inisialisasi model Gemini dengan API key dan system instruction.
  void initialize({String? apiKey}) {
    final key = apiKey ?? AppConstants.geminiApiKey;

    if (key == 'YOUR_API_KEY_HERE' || key.isEmpty) {
      throw Exception(AppConstants.errorApiKey);
    }

    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: key,
      generationConfig: GenerationConfig(
        temperature: 0.4, // Rendah untuk konsistensi klasifikasi
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 2048,
        responseMimeType: 'text/plain',
      ),
      systemInstruction: Content.system(AppConstants.geminiSystemInstruction),
    );
  }

  /// Mengklasifikasi sampah dari file gambar.
  ///
  /// [imageFile] — File gambar yang akan diklasifikasi.
  /// Returns [GeminiClassificationResult] berisi parsed JSON dan raw response.
  /// Throws [GeminiServiceException] jika terjadi error.
  Future<GeminiClassificationResult> classifyWaste(File imageFile) async {
    if (_model == null) {
      throw GeminiServiceException(
        'Gemini model belum diinisialisasi. Panggil initialize() terlebih dahulu.',
      );
    }

    try {
      // Baca file gambar sebagai bytes
      final imageBytes = await imageFile.readAsBytes();

      // Tentukan MIME type berdasarkan ekstensi
      final mimeType = _getMimeType(imageFile.path);

      // Buat content dengan gambar dan prompt
      final content = Content.multi([
        DataPart(mimeType, imageBytes),
        TextPart(
          'Analisis gambar ini dan klasifikasikan jenis sampahnya. '
          'Berikan response dalam format JSON yang valid sesuai instruksi.',
        ),
      ]);

      // Kirim ke Gemini
      final response = await _model!.generateContent([content]);
      final rawText = response.text;

      if (rawText == null || rawText.trim().isEmpty) {
        throw GeminiServiceException(
          'Gemini tidak memberikan response. Coba lagi.',
        );
      }

      // Parse JSON response
      final parsed = _parseJsonResponse(rawText);

      return GeminiClassificationResult(
        parsedData: parsed,
        rawResponse: rawText,
      );
    } on GenerativeAIException catch (e) {
      throw GeminiServiceException(
        'Error dari Gemini AI: ${e.message}',
      );
    } on FormatException catch (e) {
      throw GeminiServiceException(
        'Format response AI tidak valid: ${e.message}',
      );
    } on SocketException {
      throw GeminiServiceException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Parse response teks dari Gemini menjadi Map JSON.
  /// Menangani kasus dimana response mungkin terbungkus markdown code block.
  Map<String, dynamic> _parseJsonResponse(String rawText) {
    String cleaned = rawText.trim();

    // Hapus markdown code block jika ada (```json ... ``` atau ``` ... ```)
    if (cleaned.startsWith('```')) {
      // Hapus baris pertama (```json atau ```)
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      // Hapus ``` terakhir
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();
    }

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw GeminiServiceException(
        'Response AI bukan JSON object yang valid.',
      );
    } on FormatException {
      throw GeminiServiceException(
        'Gagal mem-parse response AI sebagai JSON. Raw: ${rawText.substring(0, rawText.length.clamp(0, 200))}',
      );
    }
  }

  /// Tentukan MIME type dari path file gambar.
  String _getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg'; // Default
    }
  }
}

/// Hasil klasifikasi dari Gemini AI.
class GeminiClassificationResult {
  /// Data yang sudah di-parse dari JSON response.
  final Map<String, dynamic> parsedData;

  /// Response mentah dari Gemini (untuk audit/debug).
  final String rawResponse;

  const GeminiClassificationResult({
    required this.parsedData,
    required this.rawResponse,
  });

  /// Nama kategori yang terklasifikasi.
  String get category =>
      (parsedData['category'] as String?) ?? 'Tidak diketahui';

  /// Tingkat keyakinan (0-100).
  double get confidence =>
      ((parsedData['confidence'] as num?) ?? 0).toDouble();

  /// Nama item yang terdeteksi.
  String get itemName =>
      (parsedData['item_name'] as String?) ?? 'Tidak diketahui';

  /// Konversi ke ScanResult model.
  /// [imagePath] — path file gambar lokal yang tersimpan.
  /// [categoryId] — ID kategori dari tabel categories.
  ScanResult toScanResult({
    required String imagePath,
    required int categoryId,
  }) {
    return ScanResult.fromAiResponse(
      jsonMap: parsedData,
      imagePath: imagePath,
      categoryId: categoryId,
      rawResponse: rawResponse,
    );
  }
}

/// Exception khusus untuk error dari GeminiService.
class GeminiServiceException implements Exception {
  final String message;
  const GeminiServiceException(this.message);

  @override
  String toString() => 'GeminiServiceException: $message';
}
