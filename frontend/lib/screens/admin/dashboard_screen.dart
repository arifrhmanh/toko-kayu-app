import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:iconsax/iconsax.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _overview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/dashboard/overview');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() => _overview = response.data['data']);
      }
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.logout),
            onPressed: () async {
              final confirm = await showConfirmDialog(context, title: 'Keluar', message: 'Yakin ingin keluar?', isDestructive: true);
              if (confirm && context.mounted) context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _isLoading
            ? const LoadingWidget()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, ${user?.namaLengkap ?? 'Admin'}!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    // Summary cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        SummaryCard(title: 'Penjualan Hari Ini', value: CurrencyFormatter.formatCompact(_overview?['today']?['sales'] ?? 0), icon: Iconsax.chart, color: AppTheme.successColor),
                        SummaryCard(title: 'Order Baru Hari Ini', value: '${_overview?['today']?['orders'] ?? 0}', icon: Iconsax.receipt_item, color: AppTheme.warningColor),
                        SummaryCard(title: 'Total Produk', value: '${_overview?['products'] ?? 0}', icon: Iconsax.box, color: AppTheme.primaryColor),
                        SummaryCard(title: 'Stok Rendah', value: '${_overview?['low_stock'] ?? 0}', icon: Iconsax.warning_2, color: AppTheme.errorColor),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Ringkasan Keuangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          _buildFinanceRow('Saldo', _overview?['saldo'] ?? 0, AppTheme.primaryColor),
                          const Divider(),
                          _buildFinanceRow('Pemasukan', _overview?['total_pemasukan'] ?? 0, AppTheme.successColor),
                          _buildFinanceRow('Pengeluaran', _overview?['total_pengeluaran'] ?? 0, AppTheme.errorColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFinanceRow(String label, int amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(CurrencyFormatter.format(amount), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
