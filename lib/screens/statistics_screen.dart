/// Smart Waste Sorting — Statistics Screen
/// Statistik penggunaan: pie chart distribusi kategori, bar chart mingguan,
/// summary cards, dan Eco Score gamification.
library;

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/scan_provider.dart';

/// Statistics screen — visualisasi data scan.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _countAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().refreshStats();
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Consumer<ScanProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              color: AppTheme.primaryGreen,
              backgroundColor: AppTheme.cardDark,
              onRefresh: () async {
                await provider.refreshStats();
                _animController.forward(from: 0);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.spacingMd),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLg),
                      child: Text(
                        AppConstants.statsTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Eco Score card
                    _buildEcoScoreCard(context, provider),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Summary cards row
                    _buildSummaryCards(context, provider),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Pie chart — distribusi kategori
                    _buildDistributionChart(context, provider),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Bar chart — weekly
                    _buildWeeklyChart(context, provider),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Category breakdown
                    _buildCategoryBreakdown(context, provider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Eco Score — gamification card
  Widget _buildEcoScoreCard(BuildContext context, ScanProvider provider) {
    final score = provider.ecoScore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
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
            // Score ring
            AnimatedBuilder(
              animation: _countAnimation,
              builder: (context, child) {
                final animatedScore = (score * _countAnimation.value).round();
                return SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value:
                              (animatedScore / 1000).clamp(0.0, 1.0),
                          strokeWidth: 6,
                          backgroundColor: AppTheme.scaffoldDark
                              .withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$animatedScore',
                            style: const TextStyle(
                              color: AppTheme.scaffoldDark,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'pts',
                            style: TextStyle(
                              color: AppTheme.scaffoldDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: AppTheme.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.statsEcoScore,
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.scaffoldDark,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getEcoMessage(score),
                    style: TextStyle(
                      color: AppTheme.scaffoldDark.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEcoMessage(int score) {
    if (score == 0) return 'Mulai scan sampahmu untuk mendapatkan skor!';
    if (score < 200) return 'Awal yang bagus! Terus scan lebih banyak sampah.';
    if (score < 500) return 'Hebat! Kamu sudah mulai peduli lingkungan.';
    if (score < 800) return 'Luar biasa! Kamu pahlawan lingkungan! 🌿';
    return 'Maksimal! Kamu ahli pengelola sampah! 🏆';
  }

  /// Summary stat cards
  Widget _buildSummaryCards(BuildContext context, ScanProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Row(
        children: [
          Expanded(
            child: _AnimatedStatCard(
              animation: _countAnimation,
              icon: Icons.document_scanner_rounded,
              label: AppConstants.statsTotalScans,
              value: provider.totalScans,
              color: AppTheme.accentBlue,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: _SummaryCard(
              icon: Icons.emoji_events_rounded,
              label: AppConstants.statsTopCategory,
              value: provider.topCategory ?? '-',
              color: AppTheme.warning,
              valueColor: provider.topCategory != null
                  ? AppTheme.getCategoryColor(provider.topCategory!)
                  : null,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: _AnimatedStatCard(
              animation: _countAnimation,
              icon: Icons.speed_rounded,
              label: 'Rata-rata',
              value: provider.averageConfidence.round(),
              suffix: '%',
              color: AppTheme.organikGreen,
            ),
          ),
        ],
      ),
    );
  }

  /// Pie chart — distribusi kategori
  Widget _buildDistributionChart(
      BuildContext context, ScanProvider provider) {
    final dist = provider.categoryDistribution;
    final total =
        dist.values.fold<int>(0, (sum, count) => sum + count);

    if (total == 0) {
      return _buildEmptyChart(
        context,
        AppConstants.statsDistribution,
        'Belum ada data scan',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: AppTheme.textTertiary.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.statsDistribution,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Pie chart
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieSections(dist, total),
                        centerSpaceRadius: 40,
                        sectionsSpace: 3,
                        startDegreeOffset: -90,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  // Legend
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dist.entries.map((e) {
                        final pct =
                            total > 0 ? (e.value / total * 100).round() : 0;
                        return _buildLegendItem(
                          e.key,
                          '${e.value} ($pct%)',
                          AppTheme.getCategoryColor(e.key),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      Map<String, int> dist, int total) {
    final entries = dist.entries.where((e) => e.value > 0).toList();

    if (entries.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: AppTheme.textTertiary.withValues(alpha: 0.2),
          title: '',
          radius: 30,
        ),
      ];
    }

    return entries.map((e) {
      final pct = (e.value / total * 100).round();
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: AppTheme.getCategoryColor(e.key),
        title: '$pct%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        radius: 30,
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bar chart — scan mingguan
  Widget _buildWeeklyChart(BuildContext context, ScanProvider provider) {
    final weeklyData = provider.weeklyData;

    if (weeklyData.isEmpty) {
      return _buildEmptyChart(
        context,
        AppConstants.statsWeekly,
        'Belum ada data minggu ini',
      );
    }

    // Prepare 7 days data
    final now = DateTime.now();
    final List<_DayData> days = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final match = weeklyData.where((d) => d['date'] == dateStr);
      final count = match.isNotEmpty ? (match.first['count'] as int?) ?? 0 : 0;
      days.add(_DayData(
        dayLabel: _shortDayName(date.weekday),
        count: count,
      ));
    }

    final maxCount =
        days.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: AppTheme.textTertiary.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.statsWeekly,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: (maxCount + 2).toDouble(),
                  barGroups: days.asMap().entries.map((entry) {
                    final i = entry.key;
                    final d = entry.value;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: d.count.toDouble(),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          gradient: AppTheme.primaryGradient,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: (maxCount + 2).toDouble(),
                            color: AppTheme.textTertiary
                                .withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: math.max(1, (maxCount / 4).ceilToDouble()),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[idx].dayLabel,
                              style: TextStyle(
                                color: idx == days.length - 1
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textTertiary,
                                fontSize: 11,
                                fontWeight: idx == days.length - 1
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        math.max(1, (maxCount / 4).ceilToDouble()),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.textTertiary.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDayName(int weekday) {
    const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return names[weekday - 1];
  }

  /// Category breakdown list
  Widget _buildCategoryBreakdown(
      BuildContext context, ScanProvider provider) {
    final dist = provider.categoryDistribution;
    final total =
        dist.values.fold<int>(0, (sum, count) => sum + count);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Kategori',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...dist.entries.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            final color = AppTheme.getCategoryColor(e.key);
            final icon = AppTheme.getCategoryIcon(e.key);

            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: color.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Text(
                          e.key,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        '${e.value} scan',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  // Progress bar
                  AnimatedBuilder(
                    animation: _countAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        child: LinearProgressIndicator(
                          value: pct * _countAnimation.value,
                          backgroundColor:
                              AppTheme.textTertiary.withValues(alpha: 0.1),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Empty chart placeholder
  Widget _buildEmptyChart(
      BuildContext context, String title, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: AppTheme.textTertiary.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppTheme.spacingLg),
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: AppTheme.textTertiary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════

class _DayData {
  final String dayLabel;
  final int count;
  const _DayData({required this.dayLabel, required this.count});
}

/// Animated stat card with counting animation
class _AnimatedStatCard extends StatelessWidget {
  final Animation<double> animation;
  final IconData icon;
  final String label;
  final int value;
  final String? suffix;
  final Color color;

  const _AnimatedStatCard({
    required this.animation,
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
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
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppTheme.spacingSm),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final animValue =
                  (value * animation.value).round();
              return Text(
                '$animValue${suffix ?? ''}',
                style:
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
              );
            },
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

/// Simple summary card (non-animated, for text values)
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color? valueColor;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.valueColor,
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
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor ?? color,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
