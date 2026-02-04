import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

enum ServiceType { auth, notes, mindmap, workflow }

/// Converts a Dio request to a curl command for easy debugging
String _toCurl(RequestOptions options) {
  final components = <String>['curl -i'];

  // Method
  if (options.method.toUpperCase() != 'GET') {
    components.add('-X ${options.method.toUpperCase()}');
  }

  // Headers
  options.headers.forEach((key, value) {
    if (value != null) {
      final escaped = value.toString().replaceAll("'", "\\'");
      components.add("-H '$key: $escaped'");
    }
  });

  // Data/Body
  if (options.data != null) {
    String body;
    if (options.data is Map || options.data is List) {
      body = jsonEncode(options.data);
    } else {
      body = options.data.toString();
    }
    final escaped = body.replaceAll("'", "\\'");
    components.add("-d '$escaped'");
  }

  // URL with query parameters
  String url = '${options.baseUrl}${options.path}';
  if (options.queryParameters.isNotEmpty) {
    final queryString = options.queryParameters.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    url = '$url?$queryString';
  }
  components.add("'$url'");

  return components.join(' \\\n  ');
}

class DioClient {
  late Dio _dio;
  final SharedPreferences _prefs;
  final ServiceType serviceType;

  DioClient(this._prefs, this.serviceType) {
    _dio = Dio();
    _setupInterceptors();
  }

  String get _baseUrl {
    final serverIp = _prefs.getString(StorageKeys.serverIp) ?? 'localhost';
    switch (serviceType) {
      case ServiceType.auth:
        return ApiConstants.authBaseUrl(serverIp);
      case ServiceType.notes:
        return ApiConstants.notesBaseUrl(serverIp);
      case ServiceType.mindmap:
        return ApiConstants.mindmapBaseUrl(serverIp);
      case ServiceType.workflow:
        return ApiConstants.workflowBaseUrl(serverIp);
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = _baseUrl;

          final accessToken = _prefs.getString(StorageKeys.accessToken);
          final tenantId = _prefs.getString(StorageKeys.tenantId);
          final userId = _prefs.getString(StorageKeys.userId);

          options.headers['Content-Type'] = 'application/json';

          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          if (tenantId != null && tenantId.isNotEmpty) {
            options.headers['X-Tenant-Id'] = tenantId;
          }
          if (userId != null && userId.isNotEmpty) {
            options.headers['X-User-Id'] = userId;
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, try to refresh
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request
              try {
                final response = await _retry(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Curl logger - logs requests as curl commands for easy debugging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final curl = _toCurl(options);
          print('\n╔══════════════════════════════════════════════════════════════');
          print('║ CURL COMMAND (copy & paste to test):');
          print('╠══════════════════════════════════════════════════════════════');
          print(curl);
          print('╚══════════════════════════════════════════════════════════════\n');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Response [${response.statusCode}]: ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Error [${error.response?.statusCode}]: ${error.requestOptions.uri}');
          print('   Message: ${error.message}');
          if (error.response?.data != null) {
            print('   Body: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = _prefs.getString(StorageKeys.refreshToken);
      if (refreshToken == null) return false;

      final serverIp = _prefs.getString(StorageKeys.serverIp) ?? 'localhost';
      final response = await Dio().post(
        '${ApiConstants.authBaseUrl(serverIp)}${ApiConstants.refreshToken}',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _prefs.setString(StorageKeys.accessToken, data['accessToken']);
        if (data['refreshToken'] != null) {
          await _prefs.setString(StorageKeys.refreshToken, data['refreshToken']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
}

// Providers for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences in main.dart');
});

// Dio client providers for each service
final authDioClientProvider = Provider<DioClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DioClient(prefs, ServiceType.auth);
});

final notesDioClientProvider = Provider<DioClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DioClient(prefs, ServiceType.notes);
});

final mindmapDioClientProvider = Provider<DioClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DioClient(prefs, ServiceType.mindmap);
});

final workflowDioClientProvider = Provider<DioClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DioClient(prefs, ServiceType.workflow);
});
