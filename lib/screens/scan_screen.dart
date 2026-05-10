/// Smart Waste Sorting — Scan Screen
/// Fitur utama: pilih gambar dari kamera/galeri, preview, kirim ke Gemini AI.
/// Modal bottom sheet untuk pilih sumber, loading state, error handling.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/scan_provider.dart';
import 'result_screen.dart';

/// Scan screen — upload/foto gambar sampah untuk klasifikasi AI.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Reset scan state when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().resetScan();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Show bottom sheet to choose image source
  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSourceSheet(ctx),
    );
  }

  /// Pick from camera and start scan
  Future<void> _pickFromCamera() async {
    Navigator.pop(context); // Close bottom sheet
    final provider = context.read<ScanProvider>();
    await provider.pickImageFromCamera();
  }

  /// Pick from gallery and start scan
  Future<void> _pickFromGallery() async {
    Navigator.pop(context); // Close bottom sheet
    final provider = context.read<ScanProvider>();
    await provider.pickImageFromGallery();
  }

  /// Start AI analysis
  Future<void> _startAnalysis() async {
    final provider = context.read<ScanProvider>();
    await provider.scanSelectedImage();

    if (!mounted) return;

    if (provider.status == ScanStatus.success && provider.currentResult != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ResultScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: const Text(AppConstants.scanTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ScanProvider>(
        builder: (context, provider, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration:
                const BoxDecoration(gradient: AppTheme.backgroundGradient),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.spacingMd),

                    // Image preview area
                    _buildImagePreview(provider),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Status / error message
                    if (provider.status == ScanStatus.error &&
                        provider.errorMessage != null)
                      _buildErrorMessage(provider.errorMessage!),

                    // Action buttons
                    if (provider.status == ScanStatus.analyzing)
                      _buildAnalyzingState()
                    else
                      _buildActionButtons(provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Image preview area — shows selected image or placeholder
  Widget _buildImagePreview(ScanProvider provider) {
    final hasImage = provider.selectedImage != null;

    return Container(
      width: double.infinity,
      height: 360,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: hasImage
              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
              : AppTheme.textTertiary.withValues(alpha: 0.15),
          width: 2,
        ),
        boxShadow: hasImage ? AppTheme.glowShadow : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl - 1),
        child: hasImage
            ? _buildImageDisplay(provider.selectedImage!)
            : _buildPlaceholder(),
      ),
    );
  }

  /// Display selected image
  Widget _buildImageDisplay(File imageFile) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          imageFile,
          fit: BoxFit.cover,
        ),
        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.scaffoldDark.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),
        // Change image button
        Positioned(
          bottom: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showSourcePicker,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: AppTheme.textTertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_rounded,
                        size: 16, color: AppTheme.textPrimary),
                    SizedBox(width: 6),
                    Text(
                      'Ganti Gambar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Placeholder when no image is selected
  Widget _buildPlaceholder() {
    return GestureDetector(
      onTap: _showSourcePicker,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                size: 44,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            AppConstants.scanInstruction,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Tap untuk memilih gambar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  /// Action buttons — pick source + analyze
  Widget _buildActionButtons(ScanProvider provider) {
    final hasImage = provider.selectedImage != null;

    return Column(
      children: [
        // Source picker buttons
        if (!hasImage) ...[
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: AppConstants.scanFromCamera,
                  color: AppTheme.primaryGreen,
                  onTap: () async {
                    await provider.pickImageFromCamera();
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_library_rounded,
                  label: AppConstants.scanFromGallery,
                  color: AppTheme.accentBlue,
                  onTap: () async {
                    await provider.pickImageFromGallery();
                  },
                ),
              ),
            ],
          ),
        ],

        // Analyze button (only when image is selected)
        if (hasImage) ...[
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _startAnalysis,
              icon: const Icon(Icons.auto_awesome, size: 22),
              label: const Text(
                'Analisis dengan AI',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.scaffoldDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Pick new image
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _showSourcePicker,
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: const Text('Pilih Gambar Lain'),
            ),
          ),
        ],
      ],
    );
  }

  /// Analyzing loading state
  Widget _buildAnalyzingState() {
    return Column(
      children: [
        const SizedBox(height: AppTheme.spacingLg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          decoration: AppTheme.glassmorphism,
          child: Column(
            children: [
              // Animated scanning indicator
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGreen),
                  backgroundColor:
                      AppTheme.textTertiary.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                AppConstants.scanAnalyzing,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'AI sedang menganalisis gambar sampah Anda...',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Error message display
  Widget _buildErrorMessage(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.error, size: 18),
            onPressed: () => context.read<ScanProvider>().clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet for choosing image source
  Widget _buildSourceSheet(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.textTertiary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Pilih Sumber Gambar',
            style: Theme.of(ctx).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: AppConstants.scanFromCamera,
                  color: AppTheme.primaryGreen,
                  onTap: _pickFromCamera,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_library_rounded,
                  label: AppConstants.scanFromGallery,
                  color: AppTheme.accentBlue,
                  onTap: _pickFromGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Source Button Widget
// ═══════════════════════════════════════════════

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
