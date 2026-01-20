import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/models/keuangan.dart';
import 'package:frontend/providers/keuangan_provider.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:iconsax/iconsax.dart';

class KeuanganListScreen extends StatefulWidget {
  const KeuanganListScreen({super.key});

  @override
  State<KeuanganListScreen> createState() => _KeuanganListScreenState();
}

class _KeuanganListScreenState extends State<KeuanganListScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<KeuanganProvider>();
    provider.fetchKeuangan(refresh: true);
    provider.fetchSummary();
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final keteranganController = TextEditingController();
    final jumlahController = TextEditingController();
    String jenis = 'pemasukan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Tambah Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SegmentedButton<String>(
                  segments: const [ButtonSegment(value: 'pemasukan', label: Text('Pemasukan')), ButtonSegment(value: 'pengeluaran', label: Text('Pengeluaran'))],
                  selected: {jenis},
                  onSelectionChanged: (s) => setModalState(() => jenis = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(controller: jumlahController, decoration: const InputDecoration(labelText: 'Jumlah', prefixIcon: Icon(Iconsax.money)), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Wajib' : null),
                const SizedBox(height: 16),
                TextFormField(controller: keteranganController, decoration: const InputDecoration(labelText: 'Keterangan', prefixIcon: Icon(Iconsax.document_text)), validator: (v) => v!.isEmpty ? 'Wajib' : null),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final success = await context.read<KeuanganProvider>().createKeuangan(jenis: jenis, jumlah: int.parse(jumlahController.text), keterangan: keteranganController.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      showSnackBar(context, success ? 'Berhasil ditambahkan' : 'Gagal', isError: !success);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keuangan')),
      body: Consumer<KeuanganProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchKeuangan(refresh: true);
              await provider.fetchSummary();
            },
            child: CustomScrollView(
              slivers: [
                // Summary
                if (provider.summary != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const Text('Saldo', style: TextStyle(color: Colors.white70)),
                          Text(CurrencyFormatter.format(provider.summary!.saldo), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(children: [const Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 12)), Text(CurrencyFormatter.formatCompact(provider.summary!.pemasukan), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                              Column(children: [const Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 12)), Text(CurrencyFormatter.formatCompact(provider.summary!.pengeluaran), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                // List
                if (provider.isLoading && provider.keuanganList.isEmpty)
                  const SliverFillRemaining(child: LoadingWidget())
                else if (provider.keuanganList.isEmpty)
                  const SliverFillRemaining(child: EmptyState(icon: Iconsax.wallet_3, title: 'Belum ada transaksi'))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = provider.keuanganList[index];
                        final isIncome = item.jenis == KeuanganJenis.pemasukan;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: (isIncome ? AppTheme.successColor : AppTheme.errorColor).withValues(alpha: 0.1), child: Icon(isIncome ? Iconsax.arrow_down : Iconsax.arrow_up, color: isIncome ? AppTheme.successColor : AppTheme.errorColor)),
                            title: Text(item.keterangan),
                            subtitle: Text(DateFormatter.formatDate(item.tanggal)),
                            trailing: Text('${isIncome ? '+' : '-'}${CurrencyFormatter.format(item.jumlah)}', style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? AppTheme.successColor : AppTheme.errorColor)),
                          ),
                        );
                      },
                      childCount: provider.keuanganList.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Iconsax.add)),
    );
  }
}
