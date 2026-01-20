import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/notifikasi_provider.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:iconsax/iconsax.dart';

class CustomerNotifikasiScreen extends StatefulWidget {
  const CustomerNotifikasiScreen({super.key});

  @override
  State<CustomerNotifikasiScreen> createState() => _CustomerNotifikasiScreenState();
}

class _CustomerNotifikasiScreenState extends State<CustomerNotifikasiScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await context.read<NotifikasiProvider>().fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: Consumer<NotifikasiProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.notifications.isEmpty) {
              return const LoadingWidget(message: 'Memuat notifikasi...');
            }

            if (provider.notifications.isEmpty) {
              return const EmptyState(
                icon: Iconsax.notification,
                title: 'Belum ada notifikasi',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notif = provider.notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: notif.isRead ? Colors.white : AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(Iconsax.notification, color: notif.isRead ? AppTheme.textHint : AppTheme.primaryColor),
                    title: Text(notif.judul, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Text(notif.pesan),
                    trailing: Text(DateFormatter.formatRelative(notif.createdAt), style: const TextStyle(fontSize: 11)),
                    onTap: () => provider.markAsRead(notif.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
