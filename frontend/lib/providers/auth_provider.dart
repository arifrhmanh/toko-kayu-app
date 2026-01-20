import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/storage_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _error;
  
  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isCustomer => _user?.isCustomer ?? false;
  
  AuthProvider() {
    // Set up logout callback
    _api.onLogout = () {
      logout();
    };
    checkAuthStatus();
  }
  
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();
    
    try {
      final isLoggedIn = await StorageService.isLoggedIn();
      
      if (!isLoggedIn) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      
      // Try to get user profile
      final response = await _api.get('/auth/profile');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _user = User.fromJson(response.data['data']['user']);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
        await StorageService.clearAll();
      }
    } catch (e) {
      // On any error during auth check, just mark as unauthenticated
      // Don't trigger logout which could cause loops
      _status = AuthStatus.unauthenticated;
      await StorageService.clearAll();
    }
    
    notifyListeners();
  }
  
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        
        _user = User.fromJson(data['user']);
        
        final tokens = data['tokens'];
        await StorageService.saveTokens(
          accessToken: tokens['access_token'],
          refreshToken: tokens['refresh_token'],
        );
        await StorageService.saveUserData(jsonEncode(data['user']));
        
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Login failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        _error = e.response?.data['message'];
      } else if (e.response?.statusCode == 401) {
        _error = 'Username atau password salah';
      } else {
        _error = 'Koneksi error. Periksa jaringan Anda.';
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register({
    required String username,
    required String password,
    required String namaLengkap,
    String? noHp,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.post('/auth/register', data: {
        'username': username,
        'password': password,
        'nama_lengkap': namaLengkap,
        'no_hp': noHp,
      });
      
      if (response.statusCode == 201 && response.data['success'] == true) {
        final data = response.data['data'];
        
        _user = User.fromJson(data['user']);
        
        final tokens = data['tokens'];
        await StorageService.saveTokens(
          accessToken: tokens['access_token'],
          refreshToken: tokens['refresh_token'],
        );
        await StorageService.saveUserData(jsonEncode(data['user']));
        
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Registration failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        _error = e.response?.data['message'];
      } else {
        _error = 'Registrasi gagal. Coba lagi.';
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> updateProfile({
    String? namaLengkap,
    String? noHp,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (namaLengkap != null) data['nama_lengkap'] = namaLengkap;
      if (noHp != null) data['no_hp'] = noHp;
      if (currentPassword != null) data['current_password'] = currentPassword;
      if (newPassword != null) data['new_password'] = newPassword;
      
      final response = await _api.put('/auth/profile', data: data);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _user = User.fromJson(response.data['data']['user']);
        await StorageService.saveUserData(jsonEncode(response.data['data']['user']));
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> logout() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      await _api.post('/auth/logout', data: {
        'refresh_token': refreshToken,
      });
    } catch (e) {
      // Ignore errors during logout
    }
    
    await StorageService.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
  
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      final dioError = error;
      if (dioError.response?.data != null) {
        return dioError.response?.data['message'] ?? 'An error occurred';
      }
      return 'Connection error. Please check your network.';
    }
    return 'An unexpected error occurred';
  }
}
