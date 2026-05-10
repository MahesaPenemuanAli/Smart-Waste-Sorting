/// Smart Waste Sorting — Category Model
/// Model data untuk kategori sampah (Organik, Anorganik, B3).
library;

import 'package:flutter/material.dart';

/// Representasi satu kategori sampah dari tabel `categories`.
class Category {
  final int? id;
  final String name;
  final String colorHex;
  final String iconName;
  final String description;
  final String disposalGuide;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
    required this.description,
    required this.disposalGuide,
    required this.createdAt,
  });

  /// Konversi dari Map (SQLite row) ke Category object.
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String,
      iconName: map['icon_name'] as String,
      description: map['description'] as String,
      disposalGuide: map['disposal_guide'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Konversi ke Map untuk insert ke SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon_name': iconName,
      'description': description,
      'disposal_guide': disposalGuide,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Parse warna hex string ke Color object Flutter.
  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Mendapatkan IconData dari nama icon Material.
  IconData get icon {
    return _iconMap[iconName] ?? Icons.help_outline;
  }

  /// Mapping nama icon string ke IconData.
  /// Digunakan karena IconData tidak bisa diserialisasi langsung.
  static const Map<String, IconData> _iconMap = {
    'eco': Icons.eco,
    'delete_outline': Icons.delete_outline,
    'warning_amber': Icons.warning_amber,
    'recycling': Icons.recycling,
    'compost': Icons.compost,
    'science': Icons.science,
  };

  @override
  String toString() => 'Category(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
