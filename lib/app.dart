/// Smart Waste Sorting — App Root Widget
/// Konfigurasi MaterialApp, theme, dan routing.
library;

import 'package:flutter/material.dart';

/// Root widget aplikasi Smart Waste Sorting.
/// Theme dan routing akan dikonfigurasi di Stage 2.
class SmartWasteApp extends StatelessWidget {
  const SmartWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Waste Sorting',
      debugShowCheckedModeBanner: false,
      // Theme akan dikonfigurasi di Stage 2
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Smart Waste Sorting — Stage 1 Complete'),
        ),
      ),
    );
  }
}
