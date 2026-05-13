/// Smart Waste Sorting — User Model
/// Model data pengguna untuk autentikasi lokal.
library;

/// Model pengguna aplikasi.
class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String? avatarUrl;
  final DateTime createdAt;

  AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.avatarUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Dari Map (SQLite row).
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Ke Map (untuk INSERT ke SQLite).
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy with updated fields.
  AppUser copyWith({String? name, String? email, String? avatarUrl}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}
