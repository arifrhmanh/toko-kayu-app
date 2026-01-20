import 'package:flutter/material.dart';
import 'package:frontend/models/kulakan.dart';
import 'package:frontend/services/api_service.dart';

class KulakanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Kulakan> _kulakanList = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  
  List<Kulakan> get kulakanList => _kulakanList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  
  Future<void> fetchKulakan({
    bool refresh = false,
    String? produkId,
    String? startDate,
    String? endDate,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    
    if (_isLoading || (!_hasMore && !refresh)) return;
    
    _isLoading = true;
    _error = null;
    if (refresh) {
      // _kulakanList = []; // Keep old data while refreshing to avoid flickering
    }
    notifyListeners();
    
    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
      };
      
      if (produkId != null) queryParams['produk_id'] = produkId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      
      final response = await _api.get('/kulakan', queryParameters: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final pagination = response.data['pagination'];
        
        final newKulakan = data.map((json) => Kulakan.fromJson(json)).toList();
        
        if (refresh) {
          _kulakanList = newKulakan;
        } else {
          _kulakanList.addAll(newKulakan);
        }
        
        _totalPages = pagination['totalPages'];
        _hasMore = _currentPage < _totalPages;
        _currentPage++;
      }
    } catch (e) {
      _error = 'Failed to fetch kulakan records';
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<Map<String, dynamic>?> createKulakan({
    required String produkId,
    required int jumlahKarung,
    required int hargaPerKarung,
    DateTime? tanggal,
  }) async {
    try {
      final response = await _api.post('/kulakan', data: {
        'produk_id': produkId,
        'jumlah_karung': jumlahKarung,
        'harga_per_karung': hargaPerKarung,
        'tanggal': tanggal?.toIso8601String(),
      });
      
      if (response.statusCode == 201 && response.data['success'] == true) {
        await fetchKulakan(refresh: true);
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<bool> deleteKulakan(String id) async {
    try {
      final response = await _api.delete('/kulakan/$id');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _kulakanList.removeWhere((k) => k.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
