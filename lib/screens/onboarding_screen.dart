/// Smart Waste Sorting — Onboarding Screen
/// 3-page onboarding edukatif tentang klasifikasi sampah.
/// Glassmorphism cards, custom animated illustrations, smooth page transitions.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import 'home_screen.dart';

/// Data model untuk satu halaman onboarding.
class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<IconData> floatingIcons;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.floatingIcons,
  });
}

/// Multi-page onboarding screen dengan glassmorphism design.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late AnimationController _iconBounceController;
  late Animation<double> _bounceAnimation;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: AppConstants.onboardingTitle1,
      description: AppConstants.onboardingDesc1,
      icon: Icons.search,
      accentColor: AppTheme.primaryGreen,
      floatingIcons: [Icons.eco, Icons.delete_outline, Icons.warning_amber],
    ),
    _OnboardingPage(
      title: AppConstants.onboardingTitle2,
      description: AppConstants.onboardingDesc2,
      icon: Icons.camera_alt_rounded,
      accentColor: AppTheme.accentBlue,
      floatingIcons: [Icons.auto_awesome, Icons.psychology, Icons.analytics],
    ),
    _OnboardingPage(
      title: AppConstants.onboardingTitle3,
      description: AppConstants.onboardingDesc3,
      icon: Icons.public,
      accentColor: AppTheme.organikGreen,
      floatingIcons: [Icons.recycling, Icons.favorite, Icons.trending_up],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _iconBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconBounceController,
        curve: Curves.elasticOut,
      ),
    );

    _iconBounceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _iconBounceController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _iconBounceController.forward(from: 0);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      AppConstants.onboardingSkip,
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(context, _pages[index], screenHeight);
                  },
                ),
              ),

              // Bottom section: indicators + button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingLg,
                  0,
                  AppTheme.spacingLg,
                  AppTheme.spacingXl,
                ),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => _buildDotIndicator(i),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _currentPage == _pages.length - 1
                            ? _completeOnboarding
                            : () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage].accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? AppConstants.onboardingGetStarted
                              : AppConstants.onboardingNext,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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

  /// Build satu halaman onboarding.
  Widget _buildPage(
    BuildContext context,
    _OnboardingPage page,
    double screenHeight,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration area
          SizedBox(
            height: screenHeight * 0.38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _floatController.value * 0.3,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: page.accentColor.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Outer ring
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: page.accentColor.withValues(alpha: 0.08),
                  ),
                ),

                // Main icon
                ScaleTransition(
                  scale: _bounceAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          page.accentColor,
                          page.accentColor.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: page.accentColor.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      page.icon,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Floating icons around the main icon
                ...List.generate(page.floatingIcons.length, (i) {
                  final angle = (i * 2 * math.pi / page.floatingIcons.length) -
                      (math.pi / 2);
                  return AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final floatOffset =
                          math.sin(_floatController.value * math.pi) * 8;
                      final radius = 130.0;
                      return Positioned(
                        left: 110 + radius * math.cos(angle) - 20,
                        top: 110 +
                            radius * math.sin(angle) +
                            floatOffset -
                            20 +
                            (screenHeight * 0.38 - 260) / 2,
                        child: child!,
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: page.accentColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        page.floatingIcons[i],
                        size: 20,
                        color: page.accentColor,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Glassmorphism text card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: AppTheme.glassmorphismColored(page.accentColor),
            child: Column(
              children: [
                Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  page.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build dot indicator untuk page position.
  Widget _buildDotIndicator(int index) {
    final isActive = index == _currentPage;
    final color = _pages[_currentPage].accentColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        color: isActive ? color : AppTheme.textTertiary.withValues(alpha: 0.3),
      ),
    );
  }
}
