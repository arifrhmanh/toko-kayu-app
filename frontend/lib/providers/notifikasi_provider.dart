import 'package:flutter/material.dart';
import 'package:frontend/models/notifikasi.dart';
import 'package:frontend/services/api_service.dart';

class NotifikasiProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Notifikasi> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  
  List<Notifikasi> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;
  
  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final queryParams = <String, dynamic>{
        'limit': 50,
      };
      
      if (unreadOnly) {
        queryParams['unread_only'] = 'true';
      }
      
      final response = await _api.get('/notifikasi', queryParameters: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> notifData = data['notifications'];
        _notifications = notifData.map((json) => Notifikasi.fromJson(json)).toList();
        _unreadCount = data['unread_count'] ?? 0;
      }
    } catch (e) {
      _error = 'Failed to fetch notifications';
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> fetchUnreadCount() async {
    try {
      final response = await _api.get('/notifikasi/count');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _unreadCount = response.data['data']['unread_count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      // Ignore errors
    }
  }
  
  Future<bool> markAsRead(String id) async {
    try {
      final response = await _api.put('/notifikasi/$id/read');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> markAllAsRead() async {
    try {
      final response = await _api.put('/notifikasi/read-all');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _api.delete('/notifikasi/$id');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final notif = _notifications.firstWhere((n) => n.id == id);
        if (!notif.isRead) {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
        _notifications.removeWhere((n) => n.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  void addNotifikasiFromRealtime(Map<String, dynamic> data) {
    final newNotif = Notifikasi.fromJson(data);
    if (!_notifications.any((n) => n.id == newNotif.id)) {
      _notifications.insert(0, newNotif);
      if (!newNotif.isRead) {
        _unreadCount++;
      }
      notifyListeners();
    }
  }
  
  void updateNotifikasiFromRealtime(Map<String, dynamic> data) {
    final updatedNotif = Notifikasi.fromJson(data);
    final index = _notifications.indexWhere((n) => n.id == updatedNotif.id);
    if (index != -1) {
      final oldNotif = _notifications[index];
      _notifications[index] = updatedNotif;
      
      // Update count if read status changed
      if (!oldNotif.isRead && updatedNotif.isRead) {
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      }
      
      notifyListeners();
    }
  }
}
