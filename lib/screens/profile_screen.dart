/// Smart Waste Sorting — Profile Screen
/// Halaman profil dengan info app, pengaturan, dan about.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import 'login_screen.dart';

/// Profile screen — info pengguna, pengaturan, tentang app.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
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
                  'Profil',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // User avatar card
              _buildUserCard(context),
              const SizedBox(height: AppTheme.spacingLg),

              // Achievement section
              _buildAchievements(context),
              const SizedBox(height: AppTheme.spacingLg),

              // Settings section
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg),
                child: Text(
                  'Pengaturan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildMenuItem(
                context,
                icon: Icons.delete_sweep_rounded,
                title: 'Hapus Semua Riwayat',
                subtitle: 'Hapus seluruh data scan',
                color: AppTheme.error,
                onTap: () => _confirmDeleteAll(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                subtitle: AppConstants.appTagline,
                color: AppTheme.accentBlue,
                onTap: () => _showAbout(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.logout_rounded,
                title: 'Keluar',
                subtitle: 'Logout dari akun Anda',
                color: AppTheme.error,
                onTap: () => _confirmLogout(context),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // App info
              Center(
                child: Column(
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Versi 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// User avatar card
  Widget _buildUserCard(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: AppTheme.glassmorphism,
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppTheme.scaffoldDark,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final name = auth.currentUser?.name ?? 'Eco Warrior';
                    return Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  _getEcoTitle(provider.ecoScore),
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildProfileStat(
                      context,
                      '${provider.totalScans}',
                      'Total Scan',
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: AppTheme.textTertiary.withValues(alpha: 0.15),
                    ),
                    _buildProfileStat(
                      context,
                      '${provider.ecoScore}',
                      'Eco Score',
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: AppTheme.textTertiary.withValues(alpha: 0.15),
                    ),
                    _buildProfileStat(
                      context,
                      provider.topCategory ?? '-',
                      'Top Kategori',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStat(
      BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  String _getEcoTitle(int score) {
    if (score == 0) return 'Pemula Lingkungan';
    if (score < 200) return 'Pemula Lingkungan 🌱';
    if (score < 500) return 'Pejuang Hijau 🌿';
    if (score < 800) return 'Pahlawan Lingkungan 🌳';
    return 'Master Eco Warrior 🏆';
  }

  /// Achievement badges
  Widget _buildAchievements(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, child) {
        final total = provider.totalScans;
        final catScanned = provider.categoryDistribution.values
            .where((c) => c > 0)
            .length;

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pencapaian',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _buildBadge(
                      context,
                      icon: Icons.camera_alt_rounded,
                      title: 'Scan Pertama',
                      unlocked: total >= 1,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: _buildBadge(
                      context,
                      icon: Icons.bolt_rounded,
                      title: '10 Scan',
                      unlocked: total >= 10,
                      color: AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: _buildBadge(
                      context,
                      icon: Icons.diversity_3_rounded,
                      title: '3 Kategori',
                      unlocked: catScanned >= 3,
                      color: AppTheme.accentPurple,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: _buildBadge(
                      context,
                      icon: Icons.star_rounded,
                      title: '50 Scan',
                      unlocked: total >= 50,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool unlocked,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: unlocked
            ? color.withValues(alpha: 0.1)
            : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: unlocked
              ? color.withValues(alpha: 0.3)
              : AppTheme.textTertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: unlocked
                ? color
                : AppTheme.textTertiary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: unlocked
                  ? color
                  : AppTheme.textTertiary.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Menu item
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: 4,
      ),
      child: Material(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Confirm delete all
  Future<void> _confirmDeleteAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Riwayat?'),
        content: const Text(
          'Tindakan ini akan menghapus seluruh data scan. '
          'Data yang dihapus tidak dapat dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await context.read<ScanProvider>().deleteAllScanResults();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Semua riwayat berhasil dihapus'),
          backgroundColor: AppTheme.cardDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    }
  }

  /// About dialog
  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appTagline,
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'Aplikasi ini menggunakan Google Gemini AI '
              'untuk mengklasifikasikan sampah secara otomatis '
              'ke dalam 3 kategori: Organik, Anorganik, dan B3.\n\n'
              'Dibuat untuk mendukung pengelolaan sampah '
              'yang lebih cerdas dan ramah lingkungan.',
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'Versi 1.0.0',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  /// Confirm logout
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda akan keluar dari akun ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await context.read<AuthProvider>().logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
