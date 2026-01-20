import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/cart_provider.dart';
import 'package:frontend/providers/order_provider.dart';
import 'package:frontend/providers/alamat_provider.dart';
import 'package:frontend/models/alamat.dart';
import 'package:frontend/screens/customer/payment_screen.dart';
import 'package:frontend/screens/customer/alamat_screen.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:iconsax/iconsax.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Alamat? _selectedAlamat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAlamat();
  }

  Future<void> _loadAlamat() async {
    final alamatProvider = context.read<AlamatProvider>();
    if (alamatProvider.alamatList.isEmpty) {
      await alamatProvider.fetchAlamat();
    }
    if (alamatProvider.alamatList.isNotEmpty) {
      setState(() {
        _selectedAlamat = alamatProvider.defaultAlamat;
      });
    }
  }

  Future<void> _checkout() async {
    if (_selectedAlamat == null) {
      showSnackBar(context, 'Pilih alamat pengiriman terlebih dahulu', isError: true);
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      showSnackBar(context, 'Keranjang kosong', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final orderProvider = context.read<OrderProvider>();
    final result = await orderProvider.createOrder(
      alamatId: _selectedAlamat!.id,
      items: cart.toOrderItems(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result != null) {
      cart.clearCart();
      
      // Navigate to payment
      final payment = result['payment'];
      if (payment != null && payment['redirect_url'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              orderId: result['order'].id,
              redirectUrl: payment['redirect_url'],
            ),
          ),
        );
      } else {
        showSnackBar(context, 'Pesanan berhasil dibuat');
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      showSnackBar(context, 'Gagal membuat pesanan', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final alamatProvider = context.watch<AlamatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alamat Section
                  const Text(
                    'Alamat Pengiriman',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push<Alamat>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlamatScreen(
                            selectMode: true,
                            selectedId: _selectedAlamat?.id,
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() => _selectedAlamat = result);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: _selectedAlamat == null
                              ? AppTheme.errorColor
                              : AppTheme.textHint,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.location, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _selectedAlamat != null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_selectedAlamat!.isDefault)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          margin: const EdgeInsets.only(bottom: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Utama',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        _selectedAlamat!.fullAddress,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : alamatProvider.alamatList.isEmpty
                                    ? const Text(
                                        'Tambahkan alamat',
                                        style: TextStyle(color: AppTheme.textSecondary),
                                      )
                                    : const Text(
                                        'Pilih alamat pengiriman',
                                        style: TextStyle(color: AppTheme.textSecondary),
                                      ),
                          ),
                          const Icon(Iconsax.arrow_right_3, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Items Section
                  const Text(
                    'Ringkasan Pesanan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Column(
                      children: [
                        for (final item in cart.items)
                          Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingMedium),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.produk.namaProduk,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.jumlah} karung x ${CurrencyFormatter.format(item.produk.hargaJual)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMedium),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(cart.totalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Note about shipping
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Iconsax.truck, color: AppTheme.infoColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ongkos kirim gratis untuk semua pesanan',
                            style: TextStyle(
                              color: AppTheme.infoColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Checkout button
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedAlamat == null ? null : _checkout,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Bayar ${CurrencyFormatter.format(cart.totalPrice)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
