/// Smart Waste Sorting — App Root Widget
/// Konfigurasi MaterialApp dengan dark theme premium dan routing.
library;

import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/constants.dart';

/// Root widget aplikasi Smart Waste Sorting.
class SmartWasteApp extends StatelessWidget {
  const SmartWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _Stage2Preview(),
    );
  }
}

/// Preview sementara untuk verifikasi Stage 2 theme.
/// Akan diganti dengan SplashScreen di Stage 4.
class _Stage2Preview extends StatelessWidget {
  const _Stage2Preview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingLg),

              // Title
              Text(
                AppConstants.appName,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                AppConstants.appTagline,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Category cards preview
              Text('Kategori Sampah', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacingMd),

              _buildCategoryCard(
                context,
                'Organik',
                'Sampah yang dapat terurai alami',
                Icons.eco,
                AppTheme.organikGradient,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              _buildCategoryCard(
                context,
                'Anorganik',
                'Sampah yang sulit terurai',
                Icons.delete_outline,
                AppTheme.anorganikGradient,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              _buildCategoryCard(
                context,
                'B3',
                'Bahan Berbahaya dan Beracun',
                Icons.warning_amber,
                AppTheme.b3Gradient,
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Glassmorphism card preview
              Text('Glassmorphism', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacingMd),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: AppTheme.glassmorphism,
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      size: 48,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'Stage 2 Complete! ✅',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Theme, Constants & Models sudah siap.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Button preview
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(AppConstants.homeScanCta),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.history),
                  label: const Text(AppConstants.historyTitle),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    LinearGradient gradient,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withValues(alpha: 0.7),
            size: 16,
          ),
        ],
      ),
    );
  }
}
