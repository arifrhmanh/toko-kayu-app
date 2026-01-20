import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/order_provider.dart';
import 'package:frontend/utils/helpers.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final String redirectUrl;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.redirectUrl,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  bool _paymentOpened = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _openPaymentInBrowser();
    } else {
      _initWebView();
    }
    
    // Start polling status after 5 seconds
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Check status every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
       if (!mounted) return;
       await _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    final status = await context.read<OrderProvider>().checkPaymentStatus(widget.orderId);
    if (status == 'dibayar' || status == 'diproses') {
      _timer?.cancel();
      if (mounted) {
        showSnackBar(context, 'Pembayaran berhasil dikonfirmasi!');
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  Future<void> _openPaymentInBrowser() async {
    setState(() => _isLoading = false);
    
    final uri = Uri.parse(widget.redirectUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _paymentOpened = true);
    }
  }

  void _initWebView() {
    // WebView only works on mobile
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // For web, show instructions instead of WebView
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.payment,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pembayaran',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _paymentOpened
                      ? 'Halaman pembayaran telah dibuka di tab baru.\nSetelah selesai membayar, sistem akan mengecek otomatis.'
                      : 'Klik tombol di bawah untuk membuka halaman pembayaran.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                if (!_paymentOpened)
                  ElevatedButton.icon(
                    onPressed: _openPaymentInBrowser,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Buka Halaman Pembayaran'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    await _checkStatus();
                    if (mounted) {
                      showSnackBar(context, 'Mengecek status pembayaran...');
                      // Give it a moment, if loop didn't catch it
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      });
                    }
                  },
                  child: const Text('Saya Sudah Membayar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // For mobile, show message (WebView would be here for actual mobile app)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pembayaran akan dibuka di browser'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(widget.redirectUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: const Text('Buka Pembayaran'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
