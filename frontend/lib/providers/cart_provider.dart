import 'package:flutter/material.dart';
import 'package:frontend/models/cart_item.dart';
import 'package:frontend/models/produk.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  
  List<CartItem> get items => List.unmodifiable(_items);
  
  int get itemCount => _items.length;
  
  int get totalItems => _items.fold(0, (sum, item) => sum + item.jumlah);
  
  int get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);
  
  bool get isEmpty => _items.isEmpty;
  
  bool get isNotEmpty => _items.isNotEmpty;
  
  CartItem? getCartItem(String produkId) {
    try {
      return _items.firstWhere((item) => item.produk.id == produkId);
    } catch (e) {
      return null;
    }
  }
  
  bool isInCart(String produkId) {
    return _items.any((item) => item.produk.id == produkId);
  }
  
  void addToCart(Produk produk, {int quantity = 1}) {
    print('addToCart called: ${produk.namaProduk}, stok: ${produk.stok}, quantity: $quantity');
    
    final existingIndex = _items.indexWhere((item) => item.produk.id == produk.id);
    
    if (existingIndex != -1) {
      // Update existing item
      final existingItem = _items[existingIndex];
      final newQuantity = existingItem.jumlah + quantity;
      
      // Check stock
      if (newQuantity > produk.stok) {
        print('Cannot add: exceeds stock');
        return; // Cannot add more than available stock
      }
      
      _items[existingIndex] = existingItem.copyWith(jumlah: newQuantity);
      print('Updated quantity to: $newQuantity');
    } else {
      // Add new item
      if (quantity > produk.stok) {
        quantity = produk.stok;
      }
      
      if (quantity > 0) {
        _items.add(CartItem(produk: produk, jumlah: quantity));
        print('Added new item to cart. Total items: ${_items.length}');
      }
    }
    
    notifyListeners();
  }
  
  void updateQuantity(String produkId, int quantity) {
    final index = _items.indexWhere((item) => item.produk.id == produkId);
    
    if (index != -1) {
      if (quantity <= 0) {
        removeFromCart(produkId);
      } else if (quantity <= _items[index].produk.stok) {
        _items[index] = _items[index].copyWith(jumlah: quantity);
        notifyListeners();
      }
    }
  }
  
  void incrementQuantity(String produkId) {
    final index = _items.indexWhere((item) => item.produk.id == produkId);
    
    if (index != -1) {
      final item = _items[index];
      if (item.jumlah < item.produk.stok) {
        _items[index] = item.copyWith(jumlah: item.jumlah + 1);
        notifyListeners();
      }
    }
  }
  
  void decrementQuantity(String produkId) {
    final index = _items.indexWhere((item) => item.produk.id == produkId);
    
    if (index != -1) {
      final item = _items[index];
      if (item.jumlah > 1) {
        _items[index] = item.copyWith(jumlah: item.jumlah - 1);
        notifyListeners();
      } else {
        removeFromCart(produkId);
      }
    }
  }
  
  void removeFromCart(String produkId) {
    _items.removeWhere((item) => item.produk.id == produkId);
    notifyListeners();
  }
  
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
  
  List<Map<String, dynamic>> toOrderItems() {
    return _items.map((item) => item.toOrderItem()).toList();
  }
  
  // Update product data when stock changes
  void updateProductStock(String produkId, int newStock) {
    final index = _items.indexWhere((item) => item.produk.id == produkId);
    
    if (index != -1) {
      final item = _items[index];
      
      if (newStock <= 0) {
        // Remove item if out of stock
        _items.removeAt(index);
      } else if (item.jumlah > newStock) {
        // Reduce quantity if it exceeds new stock
        _items[index] = item.copyWith(
          produk: item.produk.copyWith(stok: newStock),
          jumlah: newStock,
        );
      } else {
        // Just update the stock
        _items[index] = item.copyWith(
          produk: item.produk.copyWith(stok: newStock),
        );
      }
      
      notifyListeners();
    }
  }
}
