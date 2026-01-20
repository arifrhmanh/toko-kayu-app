import 'package:frontend/models/produk.dart';

class CartItem {
  final Produk produk;
  int jumlah;

  CartItem({
    required this.produk,
    this.jumlah = 1,
  });

  int get subtotal => produk.hargaJual * jumlah;

  Map<String, dynamic> toOrderItem() {
    return {
      'produk_id': produk.id,
      'jumlah': jumlah,
    };
  }

  CartItem copyWith({
    Produk? produk,
    int? jumlah,
  }) {
    return CartItem(
      produk: produk ?? this.produk,
      jumlah: jumlah ?? this.jumlah,
    );
  }
}
