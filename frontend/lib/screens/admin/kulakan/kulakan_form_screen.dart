import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/models/produk.dart';
import 'package:frontend/providers/produk_provider.dart';
import 'package:frontend/providers/kulakan_provider.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:iconsax/iconsax.dart';

class KulakanFormScreen extends StatefulWidget {
  const KulakanFormScreen({super.key});

  @override
  State<KulakanFormScreen> createState() => _KulakanFormScreenState();
}

class _KulakanFormScreenState extends State<KulakanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _hargaController = TextEditingController();
  Produk? _selectedProduk;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<ProdukProvider>().fetchProduk(refresh: true);
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  int get _totalHarga {
    final jumlah = int.tryParse(_jumlahController.text) ?? 0;
    final harga = int.tryParse(_hargaController.text) ?? 0;
    return jumlah * harga;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedProduk == null) {
      showSnackBar(context, 'Lengkapi semua field', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await context.read<KulakanProvider>().createKulakan(
      produkId: _selectedProduk!.id,
      jumlahKarung: int.parse(_jumlahController.text),
      hargaPerKarung: int.parse(_hargaController.text),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result != null) {
      showSnackBar(context, 'Kulakan berhasil ditambahkan');
      Navigator.pop(context);
    } else {
      showSnackBar(context, 'Gagal menambahkan kulakan', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Kulakan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Consumer<ProdukProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<Produk>(
                  decoration: const InputDecoration(labelText: 'Pilih Produk', prefixIcon: Icon(Iconsax.box)),
                  value: _selectedProduk,
                  items: provider.produkList.map((p) => DropdownMenuItem(value: p, child: Text(p.namaProduk))).toList(),
                  onChanged: (v) => setState(() => _selectedProduk = v),
                  validator: (v) => v == null ? 'Pilih produk' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jumlahController,
              decoration: const InputDecoration(labelText: 'Jumlah Karung', prefixIcon: Icon(Iconsax.box_1)),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hargaController,
              decoration: const InputDecoration(labelText: 'Harga per Karung', prefixIcon: Icon(Iconsax.money)),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Harga:', style: TextStyle(fontSize: 16)),
                  Text(CurrencyFormatter.format(_totalHarga), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _save, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan'))),
          ],
        ),
      ),
    );
  }
}
