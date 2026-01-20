import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/produk_provider.dart';
import 'package:frontend/providers/cart_provider.dart';
import 'package:frontend/providers/order_provider.dart';
import 'package:frontend/providers/alamat_provider.dart';
import 'package:frontend/providers/notifikasi_provider.dart';
import 'package:frontend/providers/keuangan_provider.dart';
import 'package:frontend/providers/kulakan_provider.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/customer/home_screen.dart';
import 'package:frontend/screens/admin/admin_home_screen.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/widgets/realtime_manager.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProdukProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AlamatProvider()),
        ChangeNotifierProvider(create: (_) => NotifikasiProvider()),
        ChangeNotifierProvider(create: (_) => KeuanganProvider()),
        ChangeNotifierProvider(create: (_) => KulakanProvider()),
      ],
      child: MaterialApp(
        title: 'Toko Kayu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const Scaffold(
              body: LoadingWidget(message: 'Memuat...'),
            );
          case AuthStatus.authenticated:
            if (authProvider.isAdmin) {
              return const RealtimeManager(child: AdminHomeScreen());
            }
            return const RealtimeManager(child: CustomerHomeScreen());
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return const LoginScreen();
        }
      },
    );
  }
}
