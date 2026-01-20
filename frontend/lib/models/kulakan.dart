import 'package:frontend/models/produk.dart';

class Kulakan {
  final String id;
  final String produkId;
  final int jumlahKarung;
  final int hargaPerKarung;
  final int totalHarga;
  final DateTime tanggal;
  final DateTime? createdAt;
  
  // Joined data
  final String? namaProduk;
  final String? gambarUrl;
  final Produk? produk;

  Kulakan({
    required this.id,
    required this.produkId,
    required this.jumlahKarung,
    required this.hargaPerKarung,
    required this.totalHarga,
    required this.tanggal,
    this.createdAt,
    this.namaProduk,
    this.gambarUrl,
    this.produk,
  });

  factory Kulakan.fromJson(Map<String, dynamic> json) {
    return Kulakan(
      id: json['id'] ?? '',
      produkId: json['produk_id'] ?? '',
      jumlahKarung: json['jumlah_karung'] ?? 0,
      hargaPerKarung: json['harga_per_karung'] ?? 0,
      totalHarga: json['total_harga'] ?? 0,
      tanggal: json['tanggal'] != null 
          ? DateTime.parse(json['tanggal']) 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      namaProduk: json['nama_produk'],
      gambarUrl: json['gambar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produk_id': produkId,
      'jumlah_karung': jumlahKarung,
      'harga_per_karung': hargaPerKarung,
      'total_harga': totalHarga,
      'tanggal': tanggal.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
