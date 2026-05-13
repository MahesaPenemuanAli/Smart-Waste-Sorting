/// Smart Waste Sorting — Database Service
/// SQLite database untuk menyimpan kategori sampah dan riwayat scan.
/// Menggunakan sqflite dengan migrasi, seed data, dan query statistik.
library;

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../config/constants.dart';
import '../models/category.dart';
import '../models/scan_result.dart';
import '../models/user.dart';

/// Service database lokal menggunakan SQLite.
/// Mengelola tabel `categories` dan `scan_results`.
class DatabaseService {
  static Database? _database;

  /// Singleton instance.
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Nama file database.
  static const String _dbName = 'smart_waste_sorting.db';

  /// Versi database — increment saat ada perubahan schema.
  static const int _dbVersion = 2;

  /// Mendapatkan instance database. Buat jika belum ada.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inisialisasi database — buat file, tabel, dan seed data.
  Future<Database> _initDatabase() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docDir.path, _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Konfigurasi — aktifkan foreign keys.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Buat tabel dan seed data saat database pertama kali dibuat.
  Future<void> _onCreate(Database db, int version) async {
    // ── Tabel categories ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL UNIQUE,
        color_hex       TEXT    NOT NULL,
        icon_name       TEXT    NOT NULL,
        description     TEXT    NOT NULL,
        disposal_guide  TEXT    NOT NULL,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ── Tabel scan_results ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scan_results (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id          INTEGER NOT NULL,
        image_path           TEXT    NOT NULL,
        item_name            TEXT    NOT NULL,
        confidence           REAL    NOT NULL CHECK(confidence >= 0 AND confidence <= 100),
        description          TEXT,
        disposal_tips        TEXT,
        environmental_impact TEXT,
        fun_fact             TEXT,
        raw_ai_response      TEXT,
        created_at           TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at           TEXT    NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');

    // ── Index untuk performa query ──
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_scan_results_category_id 
      ON scan_results(category_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_scan_results_created_at 
      ON scan_results(created_at DESC)
    ''');

    // ── Tabel users ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        name           TEXT    NOT NULL,
        email          TEXT    NOT NULL UNIQUE,
        password_hash  TEXT    NOT NULL,
        avatar_url     TEXT,
        created_at     TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // ── Seed data kategori ──
    await _seedCategories(db);
  }

  /// Migrasi database saat versi berubah.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: tambah tabel users
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          name           TEXT    NOT NULL,
          email          TEXT    NOT NULL UNIQUE,
          password_hash  TEXT    NOT NULL,
          avatar_url     TEXT,
          created_at     TEXT    NOT NULL DEFAULT (datetime('now'))
        )
      ''');
    }
  }

  /// Insert seed data 3 kategori sampah.
  Future<void> _seedCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final data in AppConstants.wasteCategorySeedData) {
      await db.insert('categories', {
        ...data,
        'created_at': now,
      });
    }
  }

  // ═══════════════════════════════════════════════
  // CRUD — Categories
  // ═══════════════════════════════════════════════

  /// Ambil semua kategori.
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'id ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  /// Ambil kategori berdasarkan ID.
  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  /// Ambil kategori berdasarkan nama (case-insensitive).
  Future<Category?> getCategoryByName(String name) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name.trim()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  // ═══════════════════════════════════════════════
  // CRUD — Scan Results
  // ═══════════════════════════════════════════════

  /// Insert hasil scan baru. Returns ID yang di-generate.
  Future<int> insertScanResult(ScanResult result) async {
    final db = await database;
    return db.insert('scan_results', result.toMap());
  }

  /// Ambil semua scan results dengan data kategori (JOIN).
  /// Diurutkan dari yang terbaru.
  Future<List<ScanResult>> getAllScanResults() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT 
        sr.*,
        c.name AS cat_name,
        c.color_hex AS cat_color_hex,
        c.icon_name AS cat_icon_name,
        c.description AS cat_description,
        c.disposal_guide AS cat_disposal_guide,
        c.created_at AS cat_created_at
      FROM scan_results sr
      INNER JOIN categories c ON sr.category_id = c.id
      ORDER BY sr.created_at DESC
    ''');

    return maps.map((m) {
      final category = Category(
        id: m['category_id'] as int,
        name: m['cat_name'] as String,
        colorHex: m['cat_color_hex'] as String,
        iconName: m['cat_icon_name'] as String,
        description: m['cat_description'] as String,
        disposalGuide: m['cat_disposal_guide'] as String,
        createdAt: DateTime.parse(m['cat_created_at'] as String),
      );
      return ScanResult.fromMap(m, category: category);
    }).toList();
  }

  /// Ambil scan results berdasarkan kategori ID.
  Future<List<ScanResult>> getScanResultsByCategory(int categoryId) async {
    final db = await database;
    final maps = await db.query(
      'scan_results',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => ScanResult.fromMap(m)).toList();
  }

  /// Ambil N scan results terakhir (untuk home screen).
  Future<List<ScanResult>> getRecentScanResults({int limit = 5}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT 
        sr.*,
        c.name AS cat_name,
        c.color_hex AS cat_color_hex,
        c.icon_name AS cat_icon_name,
        c.description AS cat_description,
        c.disposal_guide AS cat_disposal_guide,
        c.created_at AS cat_created_at
      FROM scan_results sr
      INNER JOIN categories c ON sr.category_id = c.id
      ORDER BY sr.created_at DESC
      LIMIT ?
    ''', [limit]);

    return maps.map((m) {
      final category = Category(
        id: m['category_id'] as int,
        name: m['cat_name'] as String,
        colorHex: m['cat_color_hex'] as String,
        iconName: m['cat_icon_name'] as String,
        description: m['cat_description'] as String,
        disposalGuide: m['cat_disposal_guide'] as String,
        createdAt: DateTime.parse(m['cat_created_at'] as String),
      );
      return ScanResult.fromMap(m, category: category);
    }).toList();
  }

  /// Ambil satu scan result berdasarkan ID.
  Future<ScanResult?> getScanResultById(int id) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT 
        sr.*,
        c.name AS cat_name,
        c.color_hex AS cat_color_hex,
        c.icon_name AS cat_icon_name,
        c.description AS cat_description,
        c.disposal_guide AS cat_disposal_guide,
        c.created_at AS cat_created_at
      FROM scan_results sr
      INNER JOIN categories c ON sr.category_id = c.id
      WHERE sr.id = ?
      LIMIT 1
    ''', [id]);

    if (maps.isEmpty) return null;

    final m = maps.first;
    final category = Category(
      id: m['category_id'] as int,
      name: m['cat_name'] as String,
      colorHex: m['cat_color_hex'] as String,
      iconName: m['cat_icon_name'] as String,
      description: m['cat_description'] as String,
      disposalGuide: m['cat_disposal_guide'] as String,
      createdAt: DateTime.parse(m['cat_created_at'] as String),
    );
    return ScanResult.fromMap(m, category: category);
  }

  /// Hapus satu scan result berdasarkan ID.
  Future<int> deleteScanResult(int id) async {
    final db = await database;
    return db.delete('scan_results', where: 'id = ?', whereArgs: [id]);
  }

  /// Hapus semua scan results.
  Future<int> deleteAllScanResults() async {
    final db = await database;
    return db.delete('scan_results');
  }

  /// Cari scan results berdasarkan item_name (LIKE search).
  Future<List<ScanResult>> searchScanResults(String query) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT 
        sr.*,
        c.name AS cat_name,
        c.color_hex AS cat_color_hex,
        c.icon_name AS cat_icon_name,
        c.description AS cat_description,
        c.disposal_guide AS cat_disposal_guide,
        c.created_at AS cat_created_at
      FROM scan_results sr
      INNER JOIN categories c ON sr.category_id = c.id
      WHERE sr.item_name LIKE ?
      ORDER BY sr.created_at DESC
    ''', ['%$query%']);

    return maps.map((m) {
      final category = Category(
        id: m['category_id'] as int,
        name: m['cat_name'] as String,
        colorHex: m['cat_color_hex'] as String,
        iconName: m['cat_icon_name'] as String,
        description: m['cat_description'] as String,
        disposalGuide: m['cat_disposal_guide'] as String,
        createdAt: DateTime.parse(m['cat_created_at'] as String),
      );
      return ScanResult.fromMap(m, category: category);
    }).toList();
  }

  // ═══════════════════════════════════════════════
  // Statistics Queries
  // ═══════════════════════════════════════════════

  /// Total jumlah scan.
  Future<int> getTotalScanCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS count FROM scan_results');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Jumlah scan per kategori.
  /// Returns a map with category name as key and count as value.
  Future<Map<String, int>> getScanCountByCategory() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT c.name, COUNT(sr.id) AS count
      FROM categories c
      LEFT JOIN scan_results sr ON c.id = sr.category_id
      GROUP BY c.id, c.name
      ORDER BY c.id ASC
    ''');

    final result = <String, int>{};
    for (final m in maps) {
      result[m['name'] as String] = (m['count'] as int?) ?? 0;
    }
    return result;
  }

  /// Kategori yang paling banyak di-scan.
  Future<String?> getTopCategory() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT c.name
      FROM scan_results sr
      INNER JOIN categories c ON sr.category_id = c.id
      GROUP BY sr.category_id
      ORDER BY COUNT(sr.id) DESC
      LIMIT 1
    ''');
    if (maps.isEmpty) return null;
    return maps.first['name'] as String?;
  }

  /// Jumlah scan hari ini.
  Future<int> getTodayScanCount() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM scan_results WHERE date(created_at) = ?",
      [today],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Jumlah scan per hari untuk 7 hari terakhir.
  /// Returns List<Map> — [{date: '2026-05-10', count: 3}, ...]
  Future<List<Map<String, dynamic>>> getWeeklyScanData() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT 
        date(created_at) AS date,
        COUNT(*) AS count
      FROM scan_results
      WHERE created_at >= datetime('now', '-7 days')
      GROUP BY date(created_at)
      ORDER BY date ASC
    ''');
    return maps;
  }

  /// Rata-rata confidence score.
  Future<double> getAverageConfidence() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(confidence) AS avg_conf FROM scan_results',
    );
    final avg = result.first['avg_conf'];
    if (avg == null) return 0.0;
    return (avg as num).toDouble();
  }

  // ═══════════════════════════════════════════════
  // CRUD — Users
  // ═══════════════════════════════════════════════

  /// Insert user baru. Return ID.
  Future<int> insertUser(AppUser user) async {
    final db = await database;
    return db.insert('users', user.toMap());
  }

  /// Ambil user berdasarkan email.
  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    if (maps.isEmpty) return null;
    return AppUser.fromMap(maps.first);
  }

  /// Ambil user berdasarkan ID.
  Future<AppUser?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return AppUser.fromMap(maps.first);
  }

  /// Update user.
  Future<int> updateUser(AppUser user) async {
    final db = await database;
    return db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // ═══════════════════════════════════════════════
  // Utility
  // ═══════════════════════════════════════════════

  /// Tutup koneksi database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Hapus database (untuk development/testing).
  Future<void> deleteDatabase() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docDir.path, _dbName);
    await databaseFactory.deleteDatabase(dbPath);
    _database = null;
  }
}
