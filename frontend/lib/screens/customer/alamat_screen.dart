import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/providers/alamat_provider.dart';
import 'package:frontend/models/alamat.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/utils/helpers.dart';
import 'package:iconsax/iconsax.dart';

class AlamatScreen extends StatefulWidget {
  final bool selectMode;
  final String? selectedId;

  const AlamatScreen({
    super.key,
    this.selectMode = false,
    this.selectedId,
  });

  @override
  State<AlamatScreen> createState() => _AlamatScreenState();
}

class _AlamatScreenState extends State<AlamatScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<AlamatProvider>().fetchAlamat();
  }

  void _showAddEditDialog([Alamat? alamat]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddEditAlamatSheet(alamat: alamat),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectMode ? 'Pilih Alamat' : 'Alamat Saya'),
      ),
      body: Consumer<AlamatProvider>(
        builder: (context, alamatProvider, child) {
          if (alamatProvider.isLoading) {
            return const LoadingWidget(message: 'Memuat alamat...');
          }

          if (alamatProvider.alamatList.isEmpty) {
            return EmptyState(
              icon: Iconsax.location,
              title: 'Belum ada alamat',
              subtitle: 'Tambahkan alamat pengiriman Anda',
              action: ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Iconsax.add),
                label: const Text('Tambah Alamat'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: alamatProvider.alamatList.length,
            itemBuilder: (context, index) {
              final alamat = alamatProvider.alamatList[index];
              final isSelected = widget.selectMode && alamat.id == widget.selectedId;

              return Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: isSelected
                      ? Border.all(color: AppTheme.primaryColor, width: 2)
                      : null,
                  boxShadow: AppTheme.shadowSmall,
                ),
                child: InkWell(
                  onTap: widget.selectMode
                      ? () => Navigator.pop(context, alamat)
                      : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (alamat.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Utama',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            if (!widget.selectMode) ...[
                              IconButton(
                                icon: const Icon(Iconsax.edit, size: 20),
                                onPressed: () => _showAddEditDialog(alamat),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Iconsax.trash,
                                  size: 20,
                                  color: AppTheme.errorColor,
                                ),
                                onPressed: () async {
                                  final confirm = await showConfirmDialog(
                                    context,
                                    title: 'Hapus Alamat',
                                    message: 'Apakah Anda yakin ingin menghapus alamat ini?',
                                    isDestructive: true,
                                  );
                                  if (confirm) {
                                    final success = await alamatProvider.deleteAlamat(alamat.id);
                                    if (mounted && !success) {
                                      showSnackBar(context, 'Gagal menghapus alamat', isError: true);
                                    }
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alamat.fullAddress,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!alamat.isDefault && !widget.selectMode) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () async {
                              final success = await alamatProvider.setDefaultAlamat(alamat.id);
                              if (mounted && !success) {
                                showSnackBar(context, 'Gagal mengubah alamat utama', isError: true);
                              }
                            },
                            child: const Text('Jadikan Utama'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: !widget.selectMode
          ? FloatingActionButton(
              onPressed: () => _showAddEditDialog(),
              child: const Icon(Iconsax.add),
            )
          : null,
    );
  }
}

class _AddEditAlamatSheet extends StatefulWidget {
  final Alamat? alamat;

  const _AddEditAlamatSheet({this.alamat});

  @override
  State<_AddEditAlamatSheet> createState() => _AddEditAlamatSheetState();
}

class _AddEditAlamatSheetState extends State<_AddEditAlamatSheet> {
  final _formKey = GlobalKey<FormState>();
  final _detailController = TextEditingController();

  Location? _selectedKota;
  Location? _selectedKecamatan;
  Location? _selectedKelurahan;
  bool _isLoading = false;

  bool get isEdit => widget.alamat != null;

  @override
  void initState() {
    super.initState();
    _loadKota();
    if (isEdit) {
      _detailController.text = widget.alamat!.detailAlamat ?? '';
    }
  }

  Future<void> _loadKota() async {
    await context.read<AlamatProvider>().fetchKota();
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKota == null || _selectedKecamatan == null || _selectedKelurahan == null) {
      showSnackBar(context, 'Pilih lokasi lengkap', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final alamatProvider = context.read<AlamatProvider>();
    bool success;

    if (isEdit) {
      success = await alamatProvider.updateAlamat(
        id: widget.alamat!.id,
        kota: _selectedKota!.nama,
        kotaId: _selectedKota!.id,
        kecamatan: _selectedKecamatan!.nama,
        kecamatanId: _selectedKecamatan!.id,
        kelurahan: _selectedKelurahan!.nama,
        kelurahanId: _selectedKelurahan!.id,
        detailAlamat: _detailController.text.trim(),
      );
    } else {
      success = await alamatProvider.createAlamat(
        kota: _selectedKota!.nama,
        kotaId: _selectedKota!.id,
        kecamatan: _selectedKecamatan!.nama,
        kecamatanId: _selectedKecamatan!.id,
        kelurahan: _selectedKelurahan!.nama,
        kelurahanId: _selectedKelurahan!.id,
        detailAlamat: _detailController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      showSnackBar(context, isEdit ? 'Alamat diperbarui' : 'Alamat ditambahkan');
      Navigator.pop(context);
    } else {
      showSnackBar(context, 'Gagal menyimpan alamat', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEdit ? 'Edit Alamat' : 'Tambah Alamat',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Kota dropdown
              Consumer<AlamatProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<Location>(
                    decoration: const InputDecoration(
                      labelText: 'Kota/Kabupaten',
                      prefixIcon: Icon(Iconsax.location),
                    ),
                    value: _selectedKota,
                    items: provider.kotaList.map((kota) {
                      return DropdownMenuItem(
                        value: kota,
                        child: Text(kota.nama),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedKota = value;
                        _selectedKecamatan = null;
                        _selectedKelurahan = null;
                      });
                      if (value != null) {
                        provider.fetchKecamatan(value.id);
                      }
                    },
                    validator: (value) {
                      if (value == null) return 'Pilih kota';
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Kecamatan dropdown
              Consumer<AlamatProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<Location>(
                    decoration: const InputDecoration(
                      labelText: 'Kecamatan',
                      prefixIcon: Icon(Iconsax.location),
                    ),
                    value: _selectedKecamatan,
                    items: provider.kecamatanList.map((kec) {
                      return DropdownMenuItem(
                        value: kec,
                        child: Text(kec.nama),
                      );
                    }).toList(),
                    onChanged: _selectedKota == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedKecamatan = value;
                              _selectedKelurahan = null;
                            });
                            if (value != null) {
                              provider.fetchKelurahan(value.id);
                            }
                          },
                    validator: (value) {
                      if (value == null) return 'Pilih kecamatan';
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Kelurahan dropdown
              Consumer<AlamatProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<Location>(
                    decoration: const InputDecoration(
                      labelText: 'Kelurahan',
                      prefixIcon: Icon(Iconsax.location),
                    ),
                    value: _selectedKelurahan,
                    items: provider.kelurahanList.map((kel) {
                      return DropdownMenuItem(
                        value: kel,
                        child: Text(kel.nama),
                      );
                    }).toList(),
                    onChanged: _selectedKecamatan == null
                        ? null
                        : (value) {
                            setState(() => _selectedKelurahan = value);
                          },
                    validator: (value) {
                      if (value == null) return 'Pilih kelurahan';
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Detail alamat
              TextFormField(
                controller: _detailController,
                decoration: const InputDecoration(
                  labelText: 'Detail Alamat (Opsional)',
                  hintText: 'Nama jalan, nomor rumah, patokan',
                  prefixIcon: Icon(Iconsax.home),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
