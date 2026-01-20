import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/order_provider.dart';
import 'package:frontend/models/order.dart';
import 'package:frontend/widgets/order_card.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/screens/customer/payment_screen.dart';
import 'package:iconsax/iconsax.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    await context.read<OrderProvider>().fetchOrders(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
              return const LoadingWidget(message: 'Memuat pesanan...');
            }

            if (orderProvider.error != null && orderProvider.orders.isEmpty) {
              return ErrorState(
                message: orderProvider.error,
                onRetry: _loadOrders,
              );
            }

            if (orderProvider.orders.isEmpty) {
              return const EmptyState(
                icon: Iconsax.receipt_item,
                title: 'Belum ada pesanan',
                subtitle: 'Pesanan Anda akan ditampilkan di sini',
              );
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 200) {
                  orderProvider.fetchOrders();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                itemCount: orderProvider.orders.length +
                    (orderProvider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= orderProvider.orders.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final order = orderProvider.orders[index];
                  return OrderCard(
                    order: order,
                    onTap: () {
                      if (order.status == OrderStatus.pending && 
                          order.midtransRedirectUrl != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              orderId: order.id,
                              redirectUrl: order.midtransRedirectUrl!,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
