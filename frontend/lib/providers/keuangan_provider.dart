import 'package:flutter/material.dart';
import 'package:frontend/models/keuangan.dart';
import 'package:frontend/services/api_service.dart';

class KeuanganProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Keuangan> _keuanganList = [];
  KeuanganSummary? _summary;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  
  List<Keuangan> get keuanganList => _keuanganList;
  KeuanganSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  
  Future<void> fetchKeuangan({
    bool refresh = false,
    String? jenis,
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
      _keuanganList = [];
    }
    notifyListeners();
    
    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'limit': 50,
      };
      
      if (jenis != null) queryParams['jenis'] = jenis;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      
      final response = await _api.get('/keuangan', queryParameters: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final pagination = response.data['pagination'];
        
        final newKeuangan = data.map((json) => Keuangan.fromJson(json)).toList();
        
        if (refresh) {
          _keuanganList = newKeuangan;
        } else {
          _keuanganList.addAll(newKeuangan);
        }
        
        _totalPages = pagination['totalPages'];
        _hasMore = _currentPage < _totalPages;
        _currentPage++;
      }
    } catch (e) {
      _error = 'Failed to fetch finance records';
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> fetchSummary({String? startDate, String? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      
      final response = await _api.get('/keuangan/summary', queryParameters: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _summary = KeuanganSummary.fromJson(response.data['data']);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to fetch summary';
    }
  }
  
  Future<bool> createKeuangan({
    required String jenis,
    required int jumlah,
    required String keterangan,
    DateTime? tanggal,
  }) async {
    try {
      final response = await _api.post('/keuangan', data: {
        'jenis': jenis,
        'jumlah': jumlah,
        'keterangan': keterangan,
        'tanggal': tanggal?.toIso8601String(),
      });
      
      if (response.statusCode == 201 && response.data['success'] == true) {
        await fetchKeuangan(refresh: true);
        await fetchSummary();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> updateKeuangan({
    required String id,
    String? jenis,
    int? jumlah,
    String? keterangan,
    DateTime? tanggal,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (jenis != null) data['jenis'] = jenis;
      if (jumlah != null) data['jumlah'] = jumlah;
      if (keterangan != null) data['keterangan'] = keterangan;
      if (tanggal != null) data['tanggal'] = tanggal.toIso8601String();
      
      final response = await _api.put('/keuangan/$id', data: data);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchKeuangan(refresh: true);
        await fetchSummary();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> deleteKeuangan(String id) async {
    try {
      final response = await _api.delete('/keuangan/$id');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _keuanganList.removeWhere((k) => k.id == id);
        await fetchSummary();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
