import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/produk_provider.dart';
import 'package:frontend/providers/order_provider.dart';
import 'package:frontend/providers/notifikasi_provider.dart';

class RealtimeManager extends StatefulWidget {
  final Widget child;

  const RealtimeManager({super.key, required this.child});

  @override
  State<RealtimeManager> createState() => _RealtimeManagerState();
}

class _RealtimeManagerState extends State<RealtimeManager> {
  final ApiService _api = ApiService();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initializeRealtime();
    _startPolling();
  }

  void _startPolling() {
    // Poll every 10 seconds as a backup for realtime
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      
      // Auto refresh data
      context.read<NotifikasiProvider>().fetchNotifications(unreadOnly: true);
      context.read<NotifikasiProvider>().fetchUnreadCount();
      
      // Refresh current active orders if any
      // We don't want to refresh complete list to avoid resetting scroll position
      // So we rely on NotificationProvider to notify user about updates, 
      // or user manual refresh for lists.
    });
  }

  void _initializeRealtime() {
    // Delay initialization to ensure providers are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final produkProvider = context.read<ProdukProvider>();
      final orderProvider = context.read<OrderProvider>();
      final notifikasiProvider = context.read<NotifikasiProvider>();
      
      _api.initializeRealtime(
        onProdukChange: (data) {
          if (data.containsKey('_deleted') && data['_deleted'] == true) {
            produkProvider.removeProdukFromRealtime(data);
          } else if (data['created_at'] == data['updated_at']) {
            // New record
            produkProvider.addProdukFromRealtime(data);
          } else {
            // Update record
            produkProvider.updateProdukFromRealtime(data);
          }
        },
        onOrderChange: (data) {
          orderProvider.handleRealtimeUpdate(data);
        },
        onNotifikasiChange: (data) {
          if (data['created_at'] == data['updated_at'] || data['is_read'] == false) {
            // New record - Fetch all notifications to update count and list
            notifikasiProvider.addNotifikasiFromRealtime(data);
            notifikasiProvider.fetchUnreadCount(); // Ensure count is synced
            
            // Show toast/snackbar for new notification
            if (data['judul'] != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(data['judul'] ?? 'Notifikasi Baru'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Lihat',
                    onPressed: () {
                      // Navigate to notification screen if needed
                    },
                  ),
                ),
              );
            }
          } else {
            // Update record (usually is_read status)
            notifikasiProvider.updateNotifikasiFromRealtime(data);
            notifikasiProvider.fetchUnreadCount();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _api.disposeRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
