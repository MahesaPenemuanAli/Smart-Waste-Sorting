/// Smart Waste Sorting — App Root Widget
/// Konfigurasi MaterialApp dengan dark theme premium dan routing.
library;

import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'screens/splash_screen.dart';

/// Root widget aplikasi Smart Waste Sorting.
class SmartWasteApp extends StatelessWidget {
  const SmartWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
