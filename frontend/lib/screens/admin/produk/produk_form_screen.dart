import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/models/produk.dart';
import 'package:frontend/providers/produk_provider.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProdukFormScreen extends StatefulWidget {
  final Produk? produk;
  const ProdukFormScreen({super.key, this.produk});

  @override
  State<ProdukFormScreen> createState() => _ProdukFormScreenState();
}

class _ProdukFormScreenState extends State<ProdukFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _stokMinController = TextEditingController();
  
  XFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  bool get isEdit => widget.produk != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _namaController.text = widget.produk!.namaProduk;
      _hargaController.text = widget.produk!.hargaJual.toString();
      _stokController.text = widget.produk!.stok.toString();
      _stokMinController.text = widget.produk!.stokMinimum.toString();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _stokMinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked != null) {
      _pickedFile = picked;
      // Read bytes for preview (works on both web and mobile)
      _imageBytes = await picked.readAsBytes();
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<ProdukProvider>();
    bool success;

    // For web, we pass the XFile path which will be handled differently
    final imagePath = _pickedFile?.path;

    if (isEdit) {
      success = await provider.updateProduk(
        id: widget.produk!.id,
        namaProduk: _namaController.text,
        hargaJual: int.parse(_hargaController.text),
        stok: int.parse(_stokController.text),
        stokMinimum: int.parse(_stokMinController.text),
        imagePath: imagePath,
      );
    } else {
      success = await provider.createProduk(
        namaProduk: _namaController.text,
        hargaJual: int.parse(_hargaController.text),
        stok: int.parse(_stokController.text),
        stokMinimum: int.parse(_stokMinController.text),
        imagePath: imagePath,
      );
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success) {
      showSnackBar(context, isEdit ? 'Produk diperbarui' : 'Produk ditambahkan');
      Navigator.pop(context);
    } else {
      showSnackBar(context, 'Gagal menyimpan produk', isError: true);
    }
  }

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      // Show picked image using bytes (works on web)
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity, height: 200),
      );
    } else if (isEdit && widget.produk!.gambarUrl != null) {
      // Show existing image from network
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.produk!.gambarUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
        ),
      );
    } else {
      // Show placeholder
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.image, size: 50, color: AppTheme.textHint),
          SizedBox(height: 8),
          Text('Tap untuk pilih gambar', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.textHint),
                ),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Produk', prefixIcon: Icon(Iconsax.box)),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hargaController,
              decoration: const InputDecoration(labelText: 'Harga Jual', prefixIcon: Icon(Iconsax.money)),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stokController,
              decoration: const InputDecoration(labelText: 'Stok (Karung)', prefixIcon: Icon(Iconsax.box_1)),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stokMinController,
              decoration: const InputDecoration(labelText: 'Stok Minimum', prefixIcon: Icon(Iconsax.warning_2)),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? 'Simpan' : 'Tambah'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
