import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/models/order.dart';
import 'package:frontend/providers/order_provider.dart';
import 'package:frontend/widgets/order_card.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:iconsax/iconsax.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderProvider>().fetchOrders(refresh: true);
  }

  void _showUpdateStatusDialog(Order order) {
    final statuses = ['dibayar', 'dikemas', 'dikirim', 'selesai'];
    final currentIndex = statuses.indexOf(order.status.name);

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ubah Status Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...statuses.asMap().entries.map((entry) {
              final isDisabled = entry.key <= currentIndex;
              return ListTile(
                leading: Icon(
                  entry.key <= currentIndex ? Iconsax.tick_circle5 : Iconsax.clock,
                  color: isDisabled ? AppTheme.successColor : AppTheme.textSecondary,
                ),
                title: Text(entry.value.capitalize(), style: TextStyle(color: isDisabled ? AppTheme.textSecondary : null)),
                onTap: isDisabled ? null : () async {
                  Navigator.pop(context);
                  final success = await context.read<OrderProvider>().updateOrderStatus(order.id, entry.value);
                  if (mounted) showSnackBar(context, success ? 'Status diperbarui' : 'Gagal memperbarui', isError: !success);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.orders.isEmpty) return const LoadingWidget();
          if (provider.orders.isEmpty) return const EmptyState(icon: Iconsax.receipt_item, title: 'Belum ada order');

          return RefreshIndicator(
            onRefresh: () => provider.fetchOrders(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.orders.length,
              itemBuilder: (context, index) {
                final order = provider.orders[index];
                return OrderCard(
                  order: order,
                  showCustomerInfo: true,
                  onTap: order.status != OrderStatus.pending && order.status != OrderStatus.selesai
                      ? () => _showUpdateStatusDialog(order)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
