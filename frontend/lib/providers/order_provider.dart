import 'package:flutter/material.dart';
import 'package:frontend/models/order.dart';
import 'package:frontend/services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  
  Future<void> fetchOrders({
    bool refresh = false,
    String? status,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    
    if (_isLoading || (!_hasMore && !refresh)) return;
    
    _isLoading = true;
    _error = null;
    if (refresh) {
      // _orders = [];
    }
    notifyListeners();
    
    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
      };
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      final response = await _api.get('/order', queryParameters: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final pagination = response.data['pagination'];
        
        final newOrders = data.map((json) => Order.fromJson(json)).toList();
        
        if (refresh) {
          _orders = newOrders;
        } else {
          _orders.addAll(newOrders);
        }
        
        _totalPages = pagination['totalPages'];
        _hasMore = _currentPage < _totalPages;
        _currentPage++;
      }
    } catch (e) {
      _error = 'Failed to fetch orders';
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<Order?> getOrderById(String id) async {
    try {
      final response = await _api.get('/order/$id');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Order.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> createOrder({
    required String alamatId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _api.post('/order', data: {
        'alamat_id': alamatId,
        'items': items,
      });
      
      if (response.statusCode == 201 && response.data['success'] == true) {
        final order = Order.fromJson(response.data['data']);
        // Check if order already exists (from realtime)
        if (!_orders.any((o) => o.id == order.id)) {
          _orders.insert(0, order);
          notifyListeners();
        }
        
        return {
          'order': order,
          'payment': response.data['data']['payment'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await _api.put('/order/$orderId/status', data: {
        'status': newStatus,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          // Refresh the order to get updated data
          final updatedOrder = await getOrderById(orderId);
          if (updatedOrder != null) {
            _orders[index] = updatedOrder;
            notifyListeners();
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> cancelOrder(String orderId) async {
    try {
      final response = await _api.delete('/order/$orderId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _orders.removeWhere((o) => o.id == orderId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<Map<String, dynamic>?> createPayment(String orderId) async {
    try {
      final response = await _api.post('/payment/create', data: {
        'order_id': orderId,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<String?> checkPaymentStatus(String orderId) async {
    try {
      final response = await _api.get('/payment/status/$orderId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['status'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  void handleRealtimeUpdate(Map<String, dynamic> data) {
    final order = Order.fromJson(data);
    final index = _orders.indexWhere((o) => o.id == order.id);
    
    if (index != -1) {
      // Update existing
      _orders[index] = order;
    } else {
      // Add new
      _orders.insert(0, order);
    }
    notifyListeners();
  }
}
