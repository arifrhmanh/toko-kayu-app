class Notifikasi {
  final String id;
  final String userId;
  final String judul;
  final String pesan;
  final String? type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  Notifikasi({
    required this.id,
    required this.userId,
    required this.judul,
    required this.pesan,
    this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      judul: json['judul'] ?? '',
      pesan: json['pesan'] ?? '',
      type: json['type'],
      referenceId: json['reference_id'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'judul': judul,
      'pesan': pesan,
      'type': type,
      'reference_id': referenceId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Notifikasi copyWith({
    String? id,
    String? userId,
    String? judul,
    String? pesan,
    String? type,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notifikasi(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      judul: judul ?? this.judul,
      pesan: pesan ?? this.pesan,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
