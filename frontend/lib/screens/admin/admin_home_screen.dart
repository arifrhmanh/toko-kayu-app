import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/notifikasi_provider.dart';
import 'package:frontend/screens/admin/dashboard_screen.dart';
import 'package:frontend/screens/admin/produk/produk_list_screen.dart';
import 'package:frontend/screens/admin/kulakan/kulakan_list_screen.dart';
import 'package:frontend/screens/admin/order/order_list_screen.dart';
import 'package:frontend/screens/admin/keuangan/keuangan_list_screen.dart';
import 'package:iconsax/iconsax.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    AdminDashboardScreen(),
    ProdukListScreen(),
    KulakanListScreen(),
    AdminOrderListScreen(),
    KeuanganListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<NotifikasiProvider>().fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Iconsax.home), activeIcon: Icon(Iconsax.home_2), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Iconsax.box), activeIcon: Icon(Iconsax.box_1), label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(Iconsax.truck), activeIcon: Icon(Iconsax.truck_tick), label: 'Kulakan'),
          BottomNavigationBarItem(icon: Icon(Iconsax.receipt_item), activeIcon: Icon(Iconsax.receipt), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Iconsax.wallet_3), activeIcon: Icon(Iconsax.wallet_1), label: 'Keuangan'),
        ],
      ),
    );
  }
}
