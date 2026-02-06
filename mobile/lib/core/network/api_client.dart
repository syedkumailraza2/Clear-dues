import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectionTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    _log('🌐 API Client initialized with baseUrl: ${ApiConstants.baseUrl}');
  }

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'API',
        error: error,
        stackTrace: stackTrace,
      );
      // Also print to console for easier viewing
      debugPrint('[API] $message');
    }
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token if available
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Log request
    _log('➡️  ${options.method} ${options.uri}');
    if (options.data != null) {
      // Hide sensitive data
      final logData = Map<String, dynamic>.from(options.data as Map);
      if (logData.containsKey('password')) {
        logData['password'] = '***';
      }
      _log('   📦 Body: $logData');
    }
    if (options.queryParameters.isNotEmpty) {
      _log('   🔍 Query: ${options.queryParameters}');
    }

    handler.next(options);
  }

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final statusCode = response.statusCode ?? 0;
    final icon = statusCode >= 200 && statusCode < 300 ? '✅' : '⚠️';

    _log('$icon ${response.requestOptions.method} ${response.requestOptions.uri} → $statusCode');

    // Log response data (truncate if too long)
    if (response.data != null) {
      final dataStr = response.data.toString();
      if (dataStr.length > 500) {
        _log('   📥 Response: ${dataStr.substring(0, 500)}...');
      } else {
        _log('   📥 Response: $dataStr');
      }
    }

    handler.next(response);
  }

  void _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) {
    _log(
      '❌ ${error.requestOptions.method} ${error.requestOptions.uri} → ${error.response?.statusCode ?? 'NO RESPONSE'}',
      error: error,
    );
    _log('   ⚠️ Error Type: ${error.type}');
    _log('   💬 Message: ${error.message}');

    if (error.response?.data != null) {
      _log('   📥 Error Response: ${error.response?.data}');
    }

    handler.next(error);
  }

  // GET request
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data;
    }
    return {'data': response.data};
  }

  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout. Please try again.');

      case DioExceptionType.connectionError:
        return NetworkException('No internet connection.');

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return NetworkException('Request cancelled.');

      default:
        return NetworkException('Something went wrong. Please try again.');
    }
  }

  AppException _handleBadResponse(Response? response) {
    if (response == null) {
      return ServerException('Server error occurred.');
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String message = 'An error occurred';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? message;
    }

    switch (statusCode) {
      case 400:
        return ValidationException(message);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 500:
      default:
        return ServerException(message);
    }
  }
}
