class Produk {
  final String id;
  final String namaProduk;
  final int hargaJual;
  final String? gambarUrl;
  final int stok;
  final int stokMinimum;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Produk({
    required this.id,
    required this.namaProduk,
    required this.hargaJual,
    this.gambarUrl,
    required this.stok,
    required this.stokMinimum,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock => stok < stokMinimum;
  bool get isOutOfStock => stok <= 0;

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'] ?? '',
      namaProduk: json['nama_produk'] ?? '',
      hargaJual: json['harga_jual'] ?? 0,
      gambarUrl: json['gambar_url'],
      stok: json['stok'] ?? 0,
      stokMinimum: json['stok_minimum'] ?? 10,
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
      'nama_produk': namaProduk,
      'harga_jual': hargaJual,
      'gambar_url': gambarUrl,
      'stok': stok,
      'stok_minimum': stokMinimum,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Produk copyWith({
    String? id,
    String? namaProduk,
    int? hargaJual,
    String? gambarUrl,
    int? stok,
    int? stokMinimum,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Produk(
      id: id ?? this.id,
      namaProduk: namaProduk ?? this.namaProduk,
      hargaJual: hargaJual ?? this.hargaJual,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      stok: stok ?? this.stok,
      stokMinimum: stokMinimum ?? this.stokMinimum,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Produk && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
