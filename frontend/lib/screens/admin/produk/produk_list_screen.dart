import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/produk_provider.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:frontend/screens/admin/produk/produk_form_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProdukListScreen extends StatefulWidget {
  const ProdukListScreen({super.key});

  @override
  State<ProdukListScreen> createState() => _ProdukListScreenState();
}

class _ProdukListScreenState extends State<ProdukListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProdukProvider>().fetchProduk(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      body: Consumer<ProdukProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.produkList.isEmpty) return const LoadingWidget();
          if (provider.produkList.isEmpty) return const EmptyState(icon: Iconsax.box, title: 'Belum ada produk');

          return RefreshIndicator(
            onRefresh: () => provider.fetchProduk(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.produkList.length,
              itemBuilder: (context, index) {
                final produk = provider.produkList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.shadowSmall),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: produk.gambarUrl != null
                            ? CachedNetworkImage(imageUrl: produk.gambarUrl!, fit: BoxFit.cover)
                            : Container(color: AppTheme.backgroundColor, child: const Icon(Iconsax.box)),
                      ),
                    ),
                    title: Text(produk.namaProduk, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(CurrencyFormatter.format(produk.hargaJual), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        Text('Stok: ${produk.stok} karung', style: TextStyle(fontSize: 12, color: produk.isLowStock ? AppTheme.warningColor : AppTheme.textSecondary)),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: AppTheme.errorColor))),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ProdukFormScreen(produk: produk)));
                        } else if (value == 'delete') {
                          final confirm = await showConfirmDialog(context, title: 'Hapus Produk', message: 'Yakin ingin menghapus ${produk.namaProduk}?', isDestructive: true);
                          if (confirm) provider.deleteProduk(produk.id);
                        }
                      },
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProdukFormScreen(produk: produk))),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProdukFormScreen())),
        child: const Icon(Iconsax.add),
      ),
    );
  }
}
