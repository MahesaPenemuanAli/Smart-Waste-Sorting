/// Smart Waste Sorting — Home Screen
/// Dashboard utama dengan greeting, quick stats, kategori sampah, dan recent scans.
/// Bottom navigation bar dengan center FAB untuk scan.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/scan_provider.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';

/// Home screen — dashboard utama aplikasi.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize provider on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ScanProvider>();
      if (!provider.isInitialized) {
        provider.initialize(apiKey: AppConstants.geminiApiKey);
      }
      provider.loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _HomeContent(onScanTap: _navigateToScan),
          const HistoryScreen(),
          const StatisticsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildScanFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _navigateToScan() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ScanScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildScanFAB() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
        boxShadow: AppTheme.glowShadow,
      ),
      child: FloatingActionButton(
        onPressed: _navigateToScan,
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: const Icon(
          Icons.document_scanner_rounded,
          size: 28,
          color: AppTheme.scaffoldDark,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.textTertiary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, AppConstants.navHome),
              _buildNavItem(1, Icons.history_rounded, AppConstants.navHistory),
              const SizedBox(width: 56), // Space for FAB
              _buildNavItem(2, Icons.bar_chart_rounded, AppConstants.navStats),
              // Placeholder for symmetry
              const SizedBox(width: 56),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentNavIndex = index),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppTheme.primaryGreen : AppTheme.textTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color:
                    isActive ? AppTheme.primaryGreen : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Home Content — The actual dashboard
// ═══════════════════════════════════════════════

class _HomeContent extends StatelessWidget {
  final VoidCallback onScanTap;
  const _HomeContent({required this.onScanTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryGreen,
          backgroundColor: AppTheme.cardDark,
          onRefresh: () async {
            final provider = context.read<ScanProvider>();
            await provider.loadHistory();
            await provider.refreshStats();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.spacingMd),
                _buildHeader(context),
                const SizedBox(height: AppTheme.spacingLg),
                _buildHeroCard(context),
                const SizedBox(height: AppTheme.spacingLg),
                _buildQuickStats(context),
                const SizedBox(height: AppTheme.spacingLg),
                _buildCategorySection(context),
                const SizedBox(height: AppTheme.spacingLg),
                _buildRecentScans(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header — greeting + avatar
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.homeGreeting,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 2),
              Text(
                AppConstants.homeSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.scaffoldDark,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Hero CTA card — scan sampahmu
  Widget _buildHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: GestureDetector(
        onTap: onScanTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: AppTheme.glowShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.homeScanCta,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.scaffoldDark,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Ambil foto atau unggah gambar\nuntuk klasifikasi instan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.scaffoldDark.withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldDark.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              size: 16, color: AppTheme.scaffoldDark),
                          SizedBox(width: 6),
                          Text(
                            'Mulai Scan',
                            style: TextStyle(
                              color: AppTheme.scaffoldDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  size: 40,
                  color: AppTheme.scaffoldDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick stats row
  Widget _buildQuickStats(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.document_scanner_rounded,
                  label: 'Scan Hari Ini',
                  value: '${provider.todayScans}',
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: _StatCard(
                  icon: Icons.analytics_rounded,
                  label: 'Total Scan',
                  value: '${provider.totalScans}',
                  color: AppTheme.accentBlue,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'Eco Score',
                  value: '${provider.ecoScore}',
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Category section — 3 waste category cards
  Widget _buildCategorySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConstants.homeCategories,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
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
        ],
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
    return Consumer<ScanProvider>(
      builder: (context, provider, child) {
        final count = provider.categoryDistribution[title] ?? 0;
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
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Recent scans section
  Widget _buildRecentScans(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, child) {
        final recentScans = provider.scanHistory.take(5).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.homeRecentScans,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              if (recentScans.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingXl),
                  decoration: AppTheme.glassmorphism,
                  child: Column(
                    children: [
                      Icon(
                        Icons.document_scanner_rounded,
                        size: 48,
                        color: AppTheme.textTertiary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        AppConstants.homeNoScans,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      ElevatedButton.icon(
                        onPressed: onScanTap,
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Scan Pertamamu'),
                      ),
                    ],
                  ),
                )
              else
                ...recentScans.map((scan) {
                  final categoryName =
                      scan.category?.name ?? 'Tidak diketahui';
                  final categoryColor =
                      AppTheme.getCategoryColor(categoryName);
                  return Container(
                    margin:
                        const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Category icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd),
                          ),
                          child: Icon(
                            AppTheme.getCategoryIcon(categoryName),
                            color: categoryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        // Item info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scan.itemName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                categoryName,
                                style: TextStyle(
                                  color: categoryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Confidence badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text(
                            '${scan.confidence.toInt()}%',
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// Stat Card Widget
// ═══════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
