enum KeuanganJenis {
  pemasukan,
  pengeluaran;

  String get displayName {
    switch (this) {
      case KeuanganJenis.pemasukan:
        return 'Pemasukan';
      case KeuanganJenis.pengeluaran:
        return 'Pengeluaran';
    }
  }

  static KeuanganJenis fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pemasukan':
        return KeuanganJenis.pemasukan;
      case 'pengeluaran':
        return KeuanganJenis.pengeluaran;
      default:
        return KeuanganJenis.pemasukan;
    }
  }
}

class Keuangan {
  final String id;
  final KeuanganJenis jenis;
  final int jumlah;
  final String keterangan;
  final String? referenceId;
  final String? referenceType;
  final DateTime tanggal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Keuangan({
    required this.id,
    required this.jenis,
    required this.jumlah,
    required this.keterangan,
    this.referenceId,
    this.referenceType,
    required this.tanggal,
    this.createdAt,
    this.updatedAt,
  });

  bool get isManual => referenceType == 'manual';
  bool get isFromOrder => referenceType == 'order';
  bool get isFromKulakan => referenceType == 'kulakan';

  factory Keuangan.fromJson(Map<String, dynamic> json) {
    return Keuangan(
      id: json['id'] ?? '',
      jenis: KeuanganJenis.fromString(json['jenis'] ?? 'pemasukan'),
      jumlah: json['jumlah'] ?? 0,
      keterangan: json['keterangan'] ?? '',
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      tanggal: json['tanggal'] != null 
          ? DateTime.parse(json['tanggal']) 
          : DateTime.now(),
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
      'jenis': jenis.name,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'tanggal': tanggal.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class KeuanganSummary {
  final int pemasukan;
  final int pengeluaran;
  final int saldo;
  final int penjualan;
  final int kulakan;
  final int profit;

  KeuanganSummary({
    required this.pemasukan,
    required this.pengeluaran,
    required this.saldo,
    required this.penjualan,
    required this.kulakan,
    required this.profit,
  });

  factory KeuanganSummary.fromJson(Map<String, dynamic> json) {
    return KeuanganSummary(
      pemasukan: json['pemasukan'] ?? 0,
      pengeluaran: json['pengeluaran'] ?? 0,
      saldo: json['saldo'] ?? 0,
      penjualan: json['penjualan'] ?? 0,
      kulakan: json['kulakan'] ?? 0,
      profit: json['profit'] ?? 0,
    );
  }
}
