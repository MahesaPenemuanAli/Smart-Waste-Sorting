/// Smart Waste Sorting — Scan Result Model
/// Model data untuk hasil scan klasifikasi sampah.
/// Menyimpan hasil analisis AI termasuk kategori, confidence, dan rekomendasi.
library;

import 'category.dart';

/// Representasi satu hasil scan dari tabel `scan_results`.
class ScanResult {
  final int? id;
  final int categoryId;
  final String imagePath;
  final String itemName;
  final double confidence;
  final String? description;
  final String? disposalTips;
  final String? environmentalImpact;
  final String? funFact;
  final String? rawAiResponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Relasi — nullable, diisi saat JOIN query.
  final Category? category;

  const ScanResult({
    this.id,
    required this.categoryId,
    required this.imagePath,
    required this.itemName,
    required this.confidence,
    this.description,
    this.disposalTips,
    this.environmentalImpact,
    this.funFact,
    this.rawAiResponse,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  /// Konversi dari Map (SQLite row) ke ScanResult object.
  factory ScanResult.fromMap(Map<String, dynamic> map, {Category? category}) {
    return ScanResult(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      imagePath: map['image_path'] as String,
      itemName: map['item_name'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      description: map['description'] as String?,
      disposalTips: map['disposal_tips'] as String?,
      environmentalImpact: map['environmental_impact'] as String?,
      funFact: map['fun_fact'] as String?,
      rawAiResponse: map['raw_ai_response'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      category: category,
    );
  }

  /// Konversi ke Map untuk insert ke SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'image_path': imagePath,
      'item_name': itemName,
      'confidence': confidence,
      'description': description,
      'disposal_tips': disposalTips,
      'environmental_impact': environmentalImpact,
      'fun_fact': funFact,
      'raw_ai_response': rawAiResponse,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Factory dari response JSON Gemini AI.
  /// [jsonMap] — parsed JSON dari response Gemini.
  /// [imagePath] — path file gambar lokal.
  /// [categoryId] — ID kategori yang sudah di-resolve.
  /// [rawResponse] — response mentah dari AI untuk audit.
  factory ScanResult.fromAiResponse({
    required Map<String, dynamic> jsonMap,
    required String imagePath,
    required int categoryId,
    String? rawResponse,
  }) {
    final now = DateTime.now();
    return ScanResult(
      categoryId: categoryId,
      imagePath: imagePath,
      itemName: (jsonMap['item_name'] as String?) ?? 'Tidak diketahui',
      confidence: ((jsonMap['confidence'] as num?) ?? 0).toDouble(),
      description: jsonMap['description'] as String?,
      disposalTips: jsonMap['disposal_tips'] as String?,
      environmentalImpact: jsonMap['environmental_impact'] as String?,
      funFact: jsonMap['fun_fact'] as String?,
      rawAiResponse: rawResponse,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Membuat salinan ScanResult dengan field tertentu diubah.
  ScanResult copyWith({
    int? id,
    int? categoryId,
    String? imagePath,
    String? itemName,
    double? confidence,
    String? description,
    String? disposalTips,
    String? environmentalImpact,
    String? funFact,
    String? rawAiResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
  }) {
    return ScanResult(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      imagePath: imagePath ?? this.imagePath,
      itemName: itemName ?? this.itemName,
      confidence: confidence ?? this.confidence,
      description: description ?? this.description,
      disposalTips: disposalTips ?? this.disposalTips,
      environmentalImpact: environmentalImpact ?? this.environmentalImpact,
      funFact: funFact ?? this.funFact,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }

  /// Label confidence dalam Bahasa Indonesia.
  String get confidenceLabel {
    if (confidence >= 90) return 'Sangat Yakin';
    if (confidence >= 75) return 'Yakin';
    if (confidence >= 50) return 'Cukup Yakin';
    if (confidence >= 25) return 'Kurang Yakin';
    return 'Tidak Yakin';
  }

  @override
  String toString() =>
      'ScanResult(id: $id, item: $itemName, category: $categoryId, confidence: $confidence%)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResult &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
