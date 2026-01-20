import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/kulakan_provider.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:frontend/screens/admin/kulakan/kulakan_form_screen.dart';
import 'package:iconsax/iconsax.dart';

class KulakanListScreen extends StatefulWidget {
  const KulakanListScreen({super.key});

  @override
  State<KulakanListScreen> createState() => _KulakanListScreenState();
}

class _KulakanListScreenState extends State<KulakanListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<KulakanProvider>().fetchKulakan(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kulakan')),
      body: Consumer<KulakanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.kulakanList.isEmpty) return const LoadingWidget();
          if (provider.kulakanList.isEmpty) return const EmptyState(icon: Iconsax.truck, title: 'Belum ada kulakan');

          return RefreshIndicator(
            onRefresh: () => provider.fetchKulakan(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.kulakanList.length,
              itemBuilder: (context, index) {
                final kulakan = provider.kulakanList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.shadowSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(kulakan.namaProduk ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(DateFormatter.formatDate(kulakan.tanggal), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${kulakan.jumlahKarung} karung x ${CurrencyFormatter.format(kulakan.hargaPerKarung)}'),
                      const SizedBox(height: 4),
                      Text('Total: ${CurrencyFormatter.format(kulakan.totalHarga)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KulakanFormScreen())),
        child: const Icon(Iconsax.add),
      ),
    );
  }
}
