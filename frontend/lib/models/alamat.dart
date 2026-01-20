class Alamat {
  final String id;
  final String userId;
  final String provinsi;
  final String? provinsiId;
  final String kota;
  final String? kotaId;
  final String kecamatan;
  final String? kecamatanId;
  final String kelurahan;
  final String? kelurahanId;
  final String? detailAlamat;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Alamat({
    required this.id,
    required this.userId,
    required this.provinsi,
    this.provinsiId,
    required this.kota,
    this.kotaId,
    required this.kecamatan,
    this.kecamatanId,
    required this.kelurahan,
    this.kelurahanId,
    this.detailAlamat,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  String get fullAddress {
    final parts = <String>[];
    if (detailAlamat != null && detailAlamat!.isNotEmpty) {
      parts.add(detailAlamat!);
    }
    parts.add(kelurahan);
    parts.add(kecamatan);
    parts.add(kota);
    parts.add(provinsi);
    return parts.join(', ');
  }

  String get shortAddress {
    return '$kecamatan, $kota';
  }

  factory Alamat.fromJson(Map<String, dynamic> json) {
    return Alamat(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      provinsi: json['provinsi'] ?? 'Jawa Timur',
      provinsiId: json['provinsi_id'],
      kota: json['kota'] ?? '',
      kotaId: json['kota_id'],
      kecamatan: json['kecamatan'] ?? '',
      kecamatanId: json['kecamatan_id'],
      kelurahan: json['kelurahan'] ?? '',
      kelurahanId: json['kelurahan_id'],
      detailAlamat: json['detail_alamat'],
      isDefault: json['is_default'] ?? false,
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
      'user_id': userId,
      'provinsi': provinsi,
      'provinsi_id': provinsiId,
      'kota': kota,
      'kota_id': kotaId,
      'kecamatan': kecamatan,
      'kecamatan_id': kecamatanId,
      'kelurahan': kelurahan,
      'kelurahan_id': kelurahanId,
      'detail_alamat': detailAlamat,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Alamat copyWith({
    String? id,
    String? userId,
    String? provinsi,
    String? provinsiId,
    String? kota,
    String? kotaId,
    String? kecamatan,
    String? kecamatanId,
    String? kelurahan,
    String? kelurahanId,
    String? detailAlamat,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Alamat(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      provinsi: provinsi ?? this.provinsi,
      provinsiId: provinsiId ?? this.provinsiId,
      kota: kota ?? this.kota,
      kotaId: kotaId ?? this.kotaId,
      kecamatan: kecamatan ?? this.kecamatan,
      kecamatanId: kecamatanId ?? this.kecamatanId,
      kelurahan: kelurahan ?? this.kelurahan,
      kelurahanId: kelurahanId ?? this.kelurahanId,
      detailAlamat: detailAlamat ?? this.detailAlamat,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Location {
  final String id;
  final String nama;
  final String? type;
  final String? postalCode;

  Location({
    required this.id,
    required this.nama,
    this.type,
    this.postalCode,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id']?.toString() ?? '',
      nama: json['nama'] ?? '',
      type: json['type'],
      postalCode: json['postal_code'],
    );
  }
}
