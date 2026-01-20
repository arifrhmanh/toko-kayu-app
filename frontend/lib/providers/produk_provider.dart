import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/models/produk.dart';
import 'package:frontend/services/api_service.dart';

class ProdukProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Produk> _produkList = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  List<Produk> get produkList => _produkList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchProduk({
    bool refresh = false,
    String? search,
    bool? lowStock,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (_isLoading || (!_hasMore && !refresh)) return;

    _isLoading = true;
    _error = null;
    if (refresh) {
      // _produkList = [];
    }
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{'page': _currentPage, 'limit': 20};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (lowStock != null) {
        queryParams['low_stock'] = lowStock.toString();
      }

      final response = await _api.get('/produk', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final pagination = response.data['pagination'];

        final newProduk = data.map((json) => Produk.fromJson(json)).toList();

        if (refresh) {
          _produkList = newProduk;
        } else {
          _produkList.addAll(newProduk);
        }

        _totalPages = pagination['totalPages'];
        _hasMore = _currentPage < _totalPages;
        _currentPage++;
      }
    } catch (e) {
      _error = 'Failed to fetch products';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Produk?> getProdukById(String id) async {
    try {
      final response = await _api.get('/produk/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Produk.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createProduk({
    required String namaProduk,
    required int hargaJual,
    int stok = 0,
    int stokMinimum = 10,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'nama_produk': namaProduk,
        'harga_jual': hargaJual,
        'stok': stok,
        'stok_minimum': stokMinimum,
      });

      if (imagePath != null) {
        // Use XFile to read bytes for web compatibility
        final xFile = XFile(imagePath);
        final bytes = await xFile.readAsBytes();
        formData.files.add(
          MapEntry(
            'gambar',
            MultipartFile.fromBytes(bytes, filename: 'product.jpg'),
          ),
        );
      }

      final response = await _api.uploadFile('/produk', data: formData);

      if (response.statusCode == 201 && response.data['success'] == true) {
        final newProduk = Produk.fromJson(response.data['data']);
        if (!_produkList.any((p) => p.id == newProduk.id)) {
          _produkList.insert(0, newProduk);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('createProduk error: $e');
      return false;
    }
  }

  Future<bool> updateProduk({
    required String id,
    String? namaProduk,
    int? hargaJual,
    int? stok,
    int? stokMinimum,
    String? imagePath,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (namaProduk != null) data['nama_produk'] = namaProduk;
      if (hargaJual != null) data['harga_jual'] = hargaJual;
      if (stok != null) data['stok'] = stok;
      if (stokMinimum != null) data['stok_minimum'] = stokMinimum;

      final formData = FormData.fromMap(data);

      if (imagePath != null) {
        // Use XFile to read bytes for web compatibility
        final xFile = XFile(imagePath);
        final bytes = await xFile.readAsBytes();
        formData.files.add(
          MapEntry(
            'gambar',
            MultipartFile.fromBytes(bytes, filename: 'product.jpg'),
          ),
        );
      }

      final response = await _api.uploadFileUpdate(
        '/produk/$id',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final updatedProduk = Produk.fromJson(response.data['data']);
        final index = _produkList.indexWhere((p) => p.id == id);
        if (index != -1) {
          _produkList[index] = updatedProduk;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('updateProduk error: $e');
      return false;
    }
  }

  Future<bool> deleteProduk(String id) async {
    try {
      final response = await _api.delete('/produk/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        _produkList.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void updateProdukFromRealtime(Map<String, dynamic> data) {
    final updatedProduk = Produk.fromJson(data);
    final index = _produkList.indexWhere((p) => p.id == updatedProduk.id);
    if (index != -1) {
      _produkList[index] = updatedProduk;
      notifyListeners();
    }
  }

  void addProdukFromRealtime(Map<String, dynamic> data) {
    final newProduk = Produk.fromJson(data);
    if (!_produkList.any((p) => p.id == newProduk.id)) {
      _produkList.insert(0, newProduk);
      notifyListeners();
    }
  }

  void removeProdukFromRealtime(Map<String, dynamic> data) {
    final id = data['id'];
    _produkList.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
