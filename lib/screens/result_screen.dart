/// Smart Waste Sorting — Result Screen
/// Menampilkan hasil klasifikasi AI secara detail.
/// Hero image, kategori badge, confidence meter, tips, dampak, fun fact.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/scan_result.dart';
import '../providers/scan_provider.dart';
import 'scan_screen.dart';

/// Result screen — tampilan hasil klasifikasi AI.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanProvider>();
    final result = provider.currentResult;

    if (result == null) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldDark,
        appBar: AppBar(title: const Text(AppConstants.resultTitle)),
        body: const Center(child: Text('Tidak ada hasil scan.')),
      );
    }

    final categoryName = result.category?.name ?? 'Tidak diketahui';
    final categoryColor = AppTheme.getCategoryColor(categoryName);
    final categoryGradient = AppTheme.getCategoryGradient(categoryName);
    final categoryIcon = AppTheme.getCategoryIcon(categoryName);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          _buildSliverAppBar(context, result, categoryGradient),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge + item name
                  _buildCategoryHeader(
                      context, result, categoryName, categoryColor, categoryIcon),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Confidence meter
                  _buildConfidenceMeter(context, result, categoryColor),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Info cards
                  if (result.description != null)
                    _buildInfoCard(
                      context,
                      icon: Icons.description_rounded,
                      title: AppConstants.resultDescription,
                      content: result.description!,
                      color: AppTheme.accentBlue,
                    ),
                  if (result.disposalTips != null)
                    _buildInfoCard(
                      context,
                      icon: Icons.recycling,
                      title: AppConstants.resultDisposalTips,
                      content: result.disposalTips!,
                      color: AppTheme.organikGreen,
                    ),
                  if (result.environmentalImpact != null)
                    _buildInfoCard(
                      context,
                      icon: Icons.public,
                      title: AppConstants.resultEnvironmentalImpact,
                      content: result.environmentalImpact!,
                      color: AppTheme.warning,
                    ),
                  if (result.funFact != null)
                    _buildInfoCard(
                      context,
                      icon: Icons.lightbulb_rounded,
                      title: AppConstants.resultFunFact,
                      content: result.funFact!,
                      color: AppTheme.accentPurple,
                    ),

                  const SizedBox(height: AppTheme.spacingMd),

                  // Timestamp
                  Center(
                    child: Text(
                      'Discan pada ${DateFormat('dd MMM yyyy, HH:mm', 'id').format(result.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Action buttons
                  _buildActionButtons(context),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sliver app bar with hero image
  Widget _buildSliverAppBar(
    BuildContext context,
    ScanResult result,
    LinearGradient gradient,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.surfaceDark,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.scaffoldDark.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (File(result.imagePath).existsSync())
              Image.file(
                File(result.imagePath),
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: BoxDecoration(gradient: gradient),
                child: const Icon(Icons.image, size: 80, color: Colors.white24),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.scaffoldDark.withValues(alpha: 0.3),
                    AppTheme.scaffoldDark,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Category badge + item name header
  Widget _buildCategoryHeader(
    BuildContext context,
    ScanResult result,
    String categoryName,
    Color categoryColor,
    IconData categoryIcon,
  ) {
    return Row(
      children: [
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(categoryIcon, color: categoryColor, size: 18),
              const SizedBox(width: 6),
              Text(
                categoryName,
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Confidence pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            result.confidenceLabel,
            style: TextStyle(
              color: categoryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Confidence meter — circular progress
  Widget _buildConfidenceMeter(
    BuildContext context,
    ScanResult result,
    Color categoryColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.glassmorphismColored(categoryColor),
      child: Row(
        children: [
          // Circular indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: result.confidence / 100,
                    strokeWidth: 6,
                    backgroundColor:
                        AppTheme.textTertiary.withValues(alpha: 0.15),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(categoryColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${result.confidence.toInt()}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingLg),
          // Item name + confidence label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.itemName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tingkat Keyakinan: ${result.confidenceLabel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Info card — deskripsi, tips, dampak, fun fact
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  /// Action buttons — scan lagi + kembali
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<ScanProvider>().resetScan();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
            },
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: const Text(AppConstants.resultScanAgain),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home_rounded, size: 18),
            label: const Text('Kembali ke Beranda'),
          ),
        ),
      ],
    );
  }
}
