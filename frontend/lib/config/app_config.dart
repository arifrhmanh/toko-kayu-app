class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kmmiyjrrvcnbpsncildu.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_SMc-EsZG31_F-a2E204WCg_PtF2sQGO',
  );

  // Midtrans Configuration
  static const String midtransClientKey = String.fromEnvironment(
    'MIDTRANS_CLIENT_KEY',
    defaultValue: 'Mid-client-H42rJcMq6pBXGsQo',
  );

  static const bool midtransIsProduction = bool.fromEnvironment(
    'MIDTRANS_IS_PRODUCTION',
    defaultValue: false,
  );

  // App Info
  static const String appName = 'Toko Kayu';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Aplikasi Jual Beli Kayu';

  // Theme Colors
  static const int primaryColorValue = 0xFF2E7D32; // Green
  static const int secondaryColorValue = 0xFF6D4C41; // Brown
  static const int accentColorValue = 0xFFFFA000; // Amber
}
