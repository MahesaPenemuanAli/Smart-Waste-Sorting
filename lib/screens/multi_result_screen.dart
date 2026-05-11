/// Smart Waste Sorting — Multi Result Screen
/// Menampilkan hasil klasifikasi dari beberapa kotak seleksi sekaligus.
/// Setiap kotak ditampilkan sebagai card: "Kotak 1: Daun — Organik".
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'scan_screen.dart';

/// Data hasil klasifikasi satu kotak.
class BoxResult {
  final int boxIndex;
  final Map<String, dynamic> parsedData;
  final File croppedImage;
  final bool saved;

  BoxResult({
    required this.boxIndex,
    required this.parsedData,
    required this.croppedImage,
    this.saved = false,
  });

  String get itemName => (parsedData['item_name'] as String?) ?? 'Tidak dikenali';
  String get category => (parsedData['category'] as String?) ?? '?';
  int get confidence => ((parsedData['confidence'] as num?) ?? 0).toInt();
  String get description => (parsedData['description'] as String?) ?? '';
  String get disposalTips => (parsedData['disposal_tips'] as String?) ?? '';
  String get environmentalImpact => (parsedData['environmental_impact'] as String?) ?? '';
  String get funFact => (parsedData['fun_fact'] as String?) ?? '';
}

/// Screen multi-result — menampilkan hasil semua kotak.
class MultiResultScreen extends StatelessWidget {
  final List<BoxResult> results;
  const MultiResultScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: Text('Hasil ${results.length} Objek'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length + 1, // +1 for action buttons
          itemBuilder: (ctx, i) {
            if (i < results.length) return _buildResultCard(ctx, results[i]);
            return _buildActionButtons(ctx);
          },
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext ctx, BoxResult r) {
    final color = AppTheme.getCategoryColor(r.category);
    final icon = AppTheme.getCategoryIcon(r.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: kotak number + image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: Image.file(r.croppedImage, fit: BoxFit.cover),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                ),
                // Box label
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Kotak ${r.boxIndex + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                // Item name overlay
                Positioned(
                  bottom: 12, left: 12, right: 12,
                  child: Text(r.itemName,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge + confidence
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color, size: 16),
                          const SizedBox(width: 6),
                          Text(r.category, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${r.confidence}%', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),

                // Description
                if (r.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(r.description, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
                ],

                // Tips
                if (r.disposalTips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.recycling, color: AppTheme.primaryGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(r.disposalTips, style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12, height: 1.4))),
                      ],
                    ),
                  ),
                ],

                // Environmental impact
                if (r.environmentalImpact.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.public, color: AppTheme.warning, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(r.environmentalImpact, style: TextStyle(color: AppTheme.warning, fontSize: 12, height: 1.4))),
                      ],
                    ),
                  ),
                ],

                // Fun fact
                if (r.funFact.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppTheme.accentPurple, size: 15),
                      const SizedBox(width: 6),
                      Expanded(child: Text(r.funFact, style: TextStyle(color: AppTheme.accentPurple, fontSize: 12, height: 1.4))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Column(children: [
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(builder: (_) => const ScanScreen()),
            ),
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: const Text('Scan Lagi'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 48,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.home_rounded, size: 18),
            label: const Text('Kembali ke Beranda'),
          ),
        ),
      ]),
    );
  }
}
