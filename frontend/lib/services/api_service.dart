import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/services/storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  bool _isRefreshing = false;
  
  // Callback to handle logout when refresh token fails
  Function? onLogout;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add access token to requests (except for login/register)
        final path = options.path;
        if (!path.contains('/auth/login') && !path.contains('/auth/register') && !path.contains('/auth/refresh')) {
          final accessToken = await StorageService.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        
        // Don't try to refresh for auth routes
        if (path.contains('/auth/')) {
          return handler.next(error);
        }
        
        // Handle 401 Unauthorized - try to refresh token
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final opts = error.requestOptions;
            final accessToken = await StorageService.getAccessToken();
            opts.headers['Authorization'] = 'Bearer $accessToken';
            
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          } else {
            // Refresh failed, logout
            _handleLogout();
          }
        }
        handler.next(error);
      },
    ));
  }
  
  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        _isRefreshing = false;
        return false;
      }
      
      final response = await Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
      )).post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccessToken = response.data['data']['access_token'];
        await StorageService.saveAccessToken(newAccessToken);
        _isRefreshing = false;
        return true;
      }
      
      _isRefreshing = false;
      return false;
    } catch (e) {
      _isRefreshing = false;
      return false;
    }
  }
  
  void _handleLogout() {
    StorageService.clearAll();
    onLogout?.call();
  }
  
  // Generic request methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.post(path, data: data, queryParameters: queryParameters);
  }
  
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.put(path, data: data, queryParameters: queryParameters);
  }
  
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.delete(path, data: data, queryParameters: queryParameters);
  }
  
  // Multipart upload
  Future<Response> uploadFile(
    String path, {
    required FormData data,
  }) async {
    return await _dio.post(
      path,
      data: data,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }
  
  Future<Response> uploadFileUpdate(
    String path, {
    required FormData data,
  }) async {
    return await _dio.put(
      path,
      data: data,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  // Supabase Client
  final _supabase = Supabase.instance.client;
  
  // Realtime subscription
  RealtimeChannel? _publicChannel;
  
  void initializeRealtime({
    Function(Map<String, dynamic>)? onProdukChange,
    Function(Map<String, dynamic>)? onOrderChange,
    Function(Map<String, dynamic>)? onNotifikasiChange,
  }) {
    if (_publicChannel != null) return;

    _publicChannel = _supabase.channel('public:db_changes');
    
    // Listen to produk changes
    if (onProdukChange != null) {
      _publicChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'produk',
        callback: (payload) {
          if (payload.newRecord != null) {
            onProdukChange(payload.newRecord!);
          } else if (payload.oldRecord != null && payload.eventType == PostgresChangeEvent.delete) {
            onProdukChange({'id': payload.oldRecord!['id'], '_deleted': true});
          }
        },
      );
    }
    
    // Listen to order changes
    if (onOrderChange != null) {
      _publicChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (payload) {
          if (payload.newRecord != null) {
            print('📦 Realtime: Order update received: ${payload.newRecord}');
            onOrderChange(payload.newRecord!);
          }
        },
      );
    }
    
    // Listen to notifikasi changes
    if (onNotifikasiChange != null) {
      _publicChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifikasi',
        callback: (payload) {
          if (payload.newRecord != null) {
            onNotifikasiChange(payload.newRecord!);
          }
        },
      );
    }
    
    _publicChannel!.subscribe(
      (status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          print('✅ Realtime connected!');
        } else if (status == RealtimeSubscribeStatus.closed) {
          print('❌ Realtime disconnected.');
        } else if (error != null) {
          print('⚠️ Realtime error: $error');
        }
      },
    );
  }
  
  void disposeRealtime() {
    if (_publicChannel != null) {
      _supabase.removeChannel(_publicChannel!);
      _publicChannel = null;
    }
  }
}
