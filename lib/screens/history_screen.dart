/// Smart Waste Sorting — History Screen
/// Riwayat semua scan dengan search, filter kategori, swipe delete.
/// Embedded di tab Home Screen (IndexedStack).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/scan_result.dart';
import '../providers/scan_provider.dart';

/// History screen — riwayat semua scan.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<ScanProvider>().searchHistory(query);
  }

  void _onFilterChanged(int? categoryId) {
    setState(() => _selectedCategoryFilter = categoryId);
    context.read<ScanProvider>().filterHistoryByCategory(categoryId);
  }

  void _onItemTap(ScanResult result) {
    final provider = context.read<ScanProvider>();
    // Set as current result to view in ResultScreen
    provider.resetScan();
    // Use a direct navigation approach — load the result from DB
    _navigateToResult(result);
  }

  Future<void> _navigateToResult(ScanResult result) async {
    // Temporarily set the current result for viewing
    final provider = context.read<ScanProvider>();

    // We need a way to view past results — let's create a dedicated result view
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _HistoryDetailScreen(result: result),
      ),
    );

    // Reload history after returning (in case something was deleted)
    provider.loadHistory();
  }

  Future<void> _confirmDelete(ScanResult result) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: Text(
          'Hapus scan "${result.itemName}" dari riwayat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && result.id != null) {
      if (!mounted) return;
      await context.read<ScanProvider>().deleteScanResult(result.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingMd),

            // Title
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: Text(
                AppConstants.historyTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Search bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: AppConstants.historySearchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Category filter chips
            _buildFilterChips(),
            const SizedBox(height: AppTheme.spacingSm),

            // List
            Expanded(
              child: Consumer<ScanProvider>(
                builder: (context, provider, child) {
                  final history = provider.scanHistory;

                  if (history.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.cardDark,
                    onRefresh: () async {
                      await provider.loadHistory();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg,
                        vertical: AppTheme.spacingSm,
                      ),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryItem(context, history[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Category filter chips
  Widget _buildFilterChips() {
    return Consumer<ScanProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Row(
            children: [
              _buildChip(
                label: 'Semua',
                isSelected: _selectedCategoryFilter == null,
                color: AppTheme.primaryGreen,
                onTap: () => _onFilterChanged(null),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              ...provider.categories.map((cat) {
                return Padding(
                  padding:
                      const EdgeInsets.only(right: AppTheme.spacingSm),
                  child: _buildChip(
                    label: cat.name,
                    isSelected: _selectedCategoryFilter == cat.id,
                    color: cat.color,
                    onTap: () => _onFilterChanged(cat.id),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : AppTheme.textTertiary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Single history item with swipe to delete
  Widget _buildHistoryItem(BuildContext context, ScanResult scan) {
    final categoryName = scan.category?.name ?? 'Tidak diketahui';
    final categoryColor = AppTheme.getCategoryColor(categoryName);
    final dateStr = DateFormat('dd MMM, HH:mm').format(scan.createdAt);

    return Dismissible(
      key: ValueKey(scan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.error),
      ),
      confirmDismiss: (_) async {
        await _confirmDelete(scan);
        return false; // We handle deletion manually
      },
      child: GestureDetector(
        onTap: () => _onItemTap(scan),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: File(scan.imagePath).existsSync()
                      ? Image.file(
                          File(scan.imagePath),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: categoryColor.withValues(alpha: 0.15),
                          child: Icon(
                            AppTheme.getCategoryIcon(categoryName),
                            color: categoryColor,
                            size: 24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.itemName,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Confidence
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${scan.confidence.toInt()}%',
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 72,
            color: AppTheme.textTertiary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            AppConstants.historyEmpty,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// History Detail Screen — view past scan result
// ═══════════════════════════════════════════════

/// Detail screen untuk melihat hasil scan dari riwayat.
class _HistoryDetailScreen extends StatelessWidget {
  final ScanResult result;
  const _HistoryDetailScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    final categoryName = result.category?.name ?? 'Tidak diketahui';
    final categoryColor = AppTheme.getCategoryColor(categoryName);
    final categoryIcon = AppTheme.getCategoryIcon(categoryName);
    final dateStr =
        DateFormat('dd MMMM yyyy, HH:mm', 'id').format(result.createdAt);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      body: CustomScrollView(
        slivers: [
          // Hero image
          SliverAppBar(
            expandedHeight: 250,
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
                  if (File(result.imagePath).existsSync())
                    Image.file(File(result.imagePath), fit: BoxFit.cover)
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.getCategoryGradient(categoryName),
                      ),
                    ),
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
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: categoryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon,
                                color: categoryColor, size: 18),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          '${result.confidence.toInt()}%',
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Item name
                  Text(
                    result.itemName,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Info sections
                  if (result.description != null)
                    _buildSection(context, Icons.description_rounded,
                        'Deskripsi', result.description!, AppTheme.accentBlue),
                  if (result.disposalTips != null)
                    _buildSection(context, Icons.recycling, 'Tips Pembuangan',
                        result.disposalTips!, AppTheme.organikGreen),
                  if (result.environmentalImpact != null)
                    _buildSection(
                        context,
                        Icons.public,
                        'Dampak Lingkungan',
                        result.environmentalImpact!,
                        AppTheme.warning),
                  if (result.funFact != null)
                    _buildSection(context, Icons.lightbulb_rounded,
                        'Fakta Menarik', result.funFact!, AppTheme.accentPurple),

                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, IconData icon, String title,
      String content, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.15)),
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
}
