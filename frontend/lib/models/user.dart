class User {
  final String id;
  final String username;
  final String role;
  final String namaLengkap;
  final String? noHp;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.namaLengkap,
    this.noHp,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'customer',
      namaLengkap: json['nama_lengkap'] ?? '',
      noHp: json['no_hp'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'nama_lengkap': namaLengkap,
      'no_hp': noHp,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? role,
    String? namaLengkap,
    String? noHp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      noHp: noHp ?? this.noHp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String accessExpiresIn;
  final String refreshExpiresIn;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresIn,
    required this.refreshExpiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      accessExpiresIn: json['access_expires_in'] ?? '15m',
      refreshExpiresIn: json['refresh_expires_in'] ?? '7d',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'access_expires_in': accessExpiresIn,
      'refresh_expires_in': refreshExpiresIn,
    };
  }
}
