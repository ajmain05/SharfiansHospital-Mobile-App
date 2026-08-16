import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../storage/local_storage.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.statusCode});

  bool get isNotFound => statusCode == 404;
}

/// Thin Dio wrapper shared by every feature repository. Backend responses are
/// consistently shaped as `{success, data}` on success and `{success:false, message}`
/// on failure (see routes/*.js on the backend) — this class normalizes both into
/// a single [ApiResponse] so repositories never touch Dio/HTTP details directly.
class ApiClient {
  static final ApiClient instance = ApiClient._internal();

  factory ApiClient() => instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = LocalStorage.getAdminToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _success(res);
    } on DioException catch (e) {
      return _fail(e);
    }
  }

  Future<ApiResponse> post(String path, [dynamic body]) async {
    try {
      final res = await _dio.post(path, data: body);
      return _success(res);
    } on DioException catch (e) {
      return _fail(e);
    }
  }

  Future<ApiResponse> put(String path, [dynamic body]) async {
    try {
      final res = await _dio.put(path, data: body);
      return _success(res);
    } on DioException catch (e) {
      return _fail(e);
    }
  }

  /// Streams a binary response (e.g. a deposit receipt PDF) straight to disk.
  Future<void> download(String path, String savePath) async {
    await _dio.download(path, savePath);
  }

  ApiResponse _success(Response res) {
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final success = body['success'];
      return ApiResponse(
        success: success is bool ? success : true,
        data: body.containsKey('data') ? body['data'] : body,
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(success: true, data: body, statusCode: res.statusCode);
  }

  ApiResponse _fail(DioException e) {
    final data = e.response?.data;
    String message;
    if (data is Map<String, dynamic>) {
      message = (data['message'] ?? data['error'] ?? _networkMessage(e))
          .toString();
    } else {
      message = _networkMessage(e);
    }
    return ApiResponse(
      success: false,
      data: data, // Preserve raw data for things like scanResult
      error: message,
      statusCode: e.response?.statusCode,
    );
  }

  String _networkMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return "Couldn't connect. Please check your internet connection.";
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}
