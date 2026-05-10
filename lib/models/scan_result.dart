/// Smart Waste Sorting — Scan Result Model
/// Model data untuk hasil scan klasifikasi sampah.
/// Akan diimplementasikan di Stage 2.
library;

/// Placeholder — akan diimplementasikan di Stage 2.
/// Model ini akan berisi: id, categoryId, imagePath, itemName,
/// confidence, description, disposalTips, environmentalImpact,
/// funFact, rawAiResponse, createdAt, updatedAt.
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

  ScanResult({
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
  });
}
