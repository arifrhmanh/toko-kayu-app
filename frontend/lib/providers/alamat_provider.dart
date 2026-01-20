import 'package:flutter/material.dart';
import 'package:frontend/models/alamat.dart';
import 'package:frontend/services/api_service.dart';

class AlamatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Alamat> _alamatList = [];
  List<Location> _kotaList = [];
  List<Location> _kecamatanList = [];
  List<Location> _kelurahanList = [];
  bool _isLoading = false;
  String? _error;
  
  List<Alamat> get alamatList => _alamatList;
  List<Location> get kotaList => _kotaList;
  List<Location> get kecamatanList => _kecamatanList;
  List<Location> get kelurahanList => _kelurahanList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Alamat? get defaultAlamat {
    try {
      return _alamatList.firstWhere((a) => a.isDefault);
    } catch (e) {
      return _alamatList.isNotEmpty ? _alamatList.first : null;
    }
  }
  
  Future<void> fetchAlamat() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.get('/alamat');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        _alamatList = data.map((json) => Alamat.fromJson(json)).toList();
      }
    } catch (e) {
      _error = 'Failed to fetch addresses';
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> fetchKota() async {
    try {
      final response = await _api.get('/alamat/kota');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        _kotaList = data.map((json) => Location.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to fetch cities';
    }
  }
  
  Future<void> fetchKecamatan(String kotaId) async {
    _kecamatanList = [];
    _kelurahanList = [];
    notifyListeners();
    
    try {
      final response = await _api.get('/alamat/kecamatan/$kotaId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        _kecamatanList = data.map((json) => Location.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to fetch districts';
    }
  }
  
  Future<void> fetchKelurahan(String kecamatanId) async {
    _kelurahanList = [];
    notifyListeners();
    
    try {
      final response = await _api.get('/alamat/kelurahan/$kecamatanId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        _kelurahanList = data.map((json) => Location.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to fetch villages';
    }
  }
  
  Future<bool> createAlamat({
    required String kota,
    required String kotaId,
    required String kecamatan,
    required String kecamatanId,
    required String kelurahan,
    required String kelurahanId,
    String? detailAlamat,
    bool isDefault = false,
  }) async {
    try {
      final response = await _api.post('/alamat', data: {
        'provinsi': 'Jawa Timur',
        'provinsi_id': '18',
        'kota': kota,
        'kota_id': kotaId,
        'kecamatan': kecamatan,
        'kecamatan_id': kecamatanId,
        'kelurahan': kelurahan,
        'kelurahan_id': kelurahanId,
        'detail_alamat': detailAlamat,
        'is_default': isDefault,
      });
      
      if (response.statusCode == 201 && response.data['success'] == true) {
        await fetchAlamat(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> updateAlamat({
    required String id,
    String? kota,
    String? kotaId,
    String? kecamatan,
    String? kecamatanId,
    String? kelurahan,
    String? kelurahanId,
    String? detailAlamat,
    bool? isDefault,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (kota != null) data['kota'] = kota;
      if (kotaId != null) data['kota_id'] = kotaId;
      if (kecamatan != null) data['kecamatan'] = kecamatan;
      if (kecamatanId != null) data['kecamatan_id'] = kecamatanId;
      if (kelurahan != null) data['kelurahan'] = kelurahan;
      if (kelurahanId != null) data['kelurahan_id'] = kelurahanId;
      if (detailAlamat != null) data['detail_alamat'] = detailAlamat;
      if (isDefault != null) data['is_default'] = isDefault;
      
      final response = await _api.put('/alamat/$id', data: data);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchAlamat(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> deleteAlamat(String id) async {
    try {
      final response = await _api.delete('/alamat/$id');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _alamatList.removeWhere((a) => a.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> setDefaultAlamat(String id) async {
    try {
      final response = await _api.put('/alamat/$id/default');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchAlamat(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  void clearLocationLists() {
    _kecamatanList = [];
    _kelurahanList = [];
    notifyListeners();
  }
}
