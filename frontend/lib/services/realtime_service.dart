import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/config/app_config.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  
  RealtimeService._internal();
  
  SupabaseClient? _client;
  final Map<String, RealtimeChannel> _channels = {};
  
  bool get isInitialized => _client != null;
  
  Future<void> initialize() async {
    if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
      print('Supabase credentials not configured, realtime disabled');
      return;
    }
    
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    
    _client = Supabase.instance.client;
    print('Supabase realtime initialized');
  }
  
  // Subscribe to orders table changes
  void subscribeToOrders({
    String? userId,
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    if (_client == null) return;
    
    final channelName = userId != null ? 'orders_$userId' : 'orders_all';
    
    // Unsubscribe if already subscribed
    _unsubscribe(channelName);
    
    final channel = _client!.channel(channelName);
    
    channel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'orders',
        filter: userId != null ? PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ) : null,
        callback: (payload) => onInsert(payload.newRecord),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'orders',
        filter: userId != null ? PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ) : null,
        callback: (payload) => onUpdate(payload.newRecord),
      )
      .subscribe();
    
    _channels[channelName] = channel;
  }
  
  // Subscribe to products table changes
  void subscribeToProducts({
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onUpdate,
    required void Function(Map<String, dynamic> payload) onDelete,
  }) {
    if (_client == null) return;
    
    const channelName = 'products';
    
    _unsubscribe(channelName);
    
    final channel = _client!.channel(channelName);
    
    channel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'produk',
        callback: (payload) => onInsert(payload.newRecord),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'produk',
        callback: (payload) => onUpdate(payload.newRecord),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'produk',
        callback: (payload) => onDelete(payload.oldRecord),
      )
      .subscribe();
    
    _channels[channelName] = channel;
  }
  
  // Subscribe to notifications table changes
  void subscribeToNotifications({
    required String userId,
    required void Function(Map<String, dynamic> payload) onInsert,
  }) {
    if (_client == null) return;
    
    final channelName = 'notifications_$userId';
    
    _unsubscribe(channelName);
    
    final channel = _client!.channel(channelName);
    
    channel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifikasi',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) => onInsert(payload.newRecord),
      )
      .subscribe();
    
    _channels[channelName] = channel;
  }
  
  void _unsubscribe(String channelName) {
    if (_channels.containsKey(channelName)) {
      _channels[channelName]?.unsubscribe();
      _channels.remove(channelName);
    }
  }
  
  void unsubscribeAll() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
  
  void dispose() {
    unsubscribeAll();
    _client = null;
  }
}
