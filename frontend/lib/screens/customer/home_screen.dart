import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/produk_provider.dart';
import 'package:frontend/providers/cart_provider.dart';
import 'package:frontend/providers/notifikasi_provider.dart';
import 'package:frontend/screens/customer/cart_screen.dart';
import 'package:frontend/screens/customer/order_history_screen.dart';
import 'package:frontend/screens/customer/notifikasi_screen.dart';
import 'package:frontend/screens/customer/profile_screen.dart';
import 'package:frontend/widgets/produk_card.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:iconsax/iconsax.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final produkProvider = context.read<ProdukProvider>();
    final notifProvider = context.read<NotifikasiProvider>();
    
    await produkProvider.fetchProduk(refresh: true);
    await notifProvider.fetchUnreadCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const OrderHistoryScreen(),
          const CustomerNotifikasiScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Consumer<NotifikasiProvider>(
        builder: (context, notifProvider, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Iconsax.home),
                activeIcon: Icon(Iconsax.home_2),
                label: 'Beranda',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Iconsax.receipt_item),
                activeIcon: Icon(Iconsax.receipt),
                label: 'Pesanan',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: notifProvider.hasUnread,
                  label: Text('${notifProvider.unreadCount}'),
                  child: const Icon(Iconsax.notification),
                ),
                activeIcon: Badge(
                  isLabelVisible: notifProvider.hasUnread,
                  label: Text('${notifProvider.unreadCount}'),
                  child: const Icon(Iconsax.notification_1),
                ),
                label: 'Notifikasi',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Iconsax.user),
                activeIcon: Icon(Iconsax.profile_circle),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Kayu'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: cart.isNotEmpty,
                  label: Text('${cart.totalItems}'),
                  child: const Icon(Iconsax.shopping_cart),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Iconsax.search_normal),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ProdukProvider>().fetchProduk(refresh: true);
                          },
                        )
                      : null,
                ),
                onSubmitted: (value) {
                  context.read<ProdukProvider>().fetchProduk(
                    refresh: true,
                    search: value,
                  );
                },
              ),
            ),
            // Products grid
            Expanded(
              child: Consumer<ProdukProvider>(
                builder: (context, produkProvider, child) {
                  if (produkProvider.isLoading && produkProvider.produkList.isEmpty) {
                    return const LoadingWidget(message: 'Memuat produk...');
                  }

                  if (produkProvider.error != null && produkProvider.produkList.isEmpty) {
                    return ErrorState(
                      message: produkProvider.error,
                      onRetry: () => produkProvider.fetchProduk(refresh: true),
                    );
                  }

                  if (produkProvider.produkList.isEmpty) {
                    return const EmptyState(
                      icon: Iconsax.box,
                      title: 'Belum ada produk',
                      subtitle: 'Produk akan ditampilkan di sini',
                    );
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification &&
                          notification.metrics.extentAfter < 200) {
                        produkProvider.fetchProduk();
                      }
                      return false;
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.55,
                        crossAxisSpacing: AppTheme.spacingSmall,
                        mainAxisSpacing: AppTheme.spacingSmall,
                      ),
                      itemCount: produkProvider.produkList.length +
                          (produkProvider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= produkProvider.produkList.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final produk = produkProvider.produkList[index];
                        print('Produk: ${produk.namaProduk}, stok: ${produk.stok}, isOutOfStock: ${produk.isOutOfStock}');
                        return ProdukCard(
                          produk: produk,
                          onTap: () {
                            // Navigate to detail
                          },
                          onAddToCart: produk.isOutOfStock
                              ? null
                              : () {
                                  print('Button pressed for: ${produk.namaProduk}');
                                  context.read<CartProvider>().addToCart(produk);
                                  showSnackBar(
                                    context,
                                    '${produk.namaProduk} ditambahkan ke keranjang',
                                  );
                                },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
