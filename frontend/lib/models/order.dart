import 'package:frontend/models/produk.dart';
import 'package:frontend/models/alamat.dart';

enum OrderStatus {
  pending,
  dibayar,
  dikemas,
  dikirim,
  selesai,
  expired,
  batal;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Menunggu Pembayaran';
      case OrderStatus.dibayar:
        return 'Dibayar';
      case OrderStatus.dikemas:
        return 'Dikemas';
      case OrderStatus.dikirim:
        return 'Dikirim';
      case OrderStatus.selesai:
        return 'Selesai';
      case OrderStatus.expired:
        return 'Expired';
      case OrderStatus.batal:
        return 'Dibatalkan';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'dibayar':
        return OrderStatus.dibayar;
      case 'dikemas':
        return OrderStatus.dikemas;
      case 'dikirim':
        return OrderStatus.dikirim;
      case 'selesai':
        return OrderStatus.selesai;
      case 'expired':
      case 'expire': // Midtrans sends 'expire'
        return OrderStatus.expired;
      case 'batal':
      case 'cancel': // Midtrans sends 'cancel'
        return OrderStatus.batal;
      default:
        return OrderStatus.pending;
    }
  }
}

class Order {
  final String id;
  final String userId;
  final String? alamatId;
  final OrderStatus status;
  final int totalHarga;
  final String? midtransOrderId;
  final String? midtransToken;
  final String? midtransRedirectUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Joined data
  final String? username;
  final String? namaLengkap;
  final String? noHp;
  final Alamat? alamat;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.userId,
    this.alamatId,
    required this.status,
    required this.totalHarga,
    this.midtransOrderId,
    this.midtransToken,
    this.midtransRedirectUrl,
    this.createdAt,
    this.updatedAt,
    this.username,
    this.namaLengkap,
    this.noHp,
    this.alamat,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    Alamat? alamat;
    if (json['kota'] != null || json['kecamatan'] != null) {
      alamat = Alamat(
        id: json['alamat_id'] ?? '',
        userId: json['user_id'] ?? '',
        provinsi: json['provinsi'] ?? 'Jawa Timur',
        kota: json['kota'] ?? '',
        kecamatan: json['kecamatan'] ?? '',
        kelurahan: json['kelurahan'] ?? '',
        detailAlamat: json['detail_alamat'],
      );
    }

    List<OrderItem>? items;
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    return Order(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      alamatId: json['alamat_id'],
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      totalHarga: json['total_harga'] ?? 0,
      midtransOrderId: json['midtrans_order_id'],
      midtransToken: json['midtrans_token'],
      midtransRedirectUrl: json['midtrans_redirect_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
      username: json['username'],
      namaLengkap: json['nama_lengkap'],
      noHp: json['no_hp'],
      alamat: alamat,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'alamat_id': alamatId,
      'status': status.name,
      'total_harga': totalHarga,
      'midtrans_order_id': midtransOrderId,
      'midtrans_token': midtransToken,
      'midtrans_redirect_url': midtransRedirectUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String produkId;
  final int jumlah;
  final int hargaSatuan;
  final int subtotal;
  final DateTime? createdAt;
  
  // Joined data
  final String? namaProduk;
  final String? gambarUrl;
  final Produk? produk;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.produkId,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.createdAt,
    this.namaProduk,
    this.gambarUrl,
    this.produk,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      produkId: json['produk_id'] ?? '',
      jumlah: json['jumlah'] ?? 0,
      hargaSatuan: json['harga_satuan'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
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
      'order_id': orderId,
      'produk_id': produkId,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
