import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient._({
    required this.appConfig,
    required Dio dio,
    required PersistCookieJar cookieJar,
  })  : _dio = dio,
        _cookieJar = cookieJar;

  final AppConfig appConfig;
  final Dio _dio;
  final PersistCookieJar _cookieJar;

  static Future<ApiClient> create(AppConfig appConfig) async {
    final supportDir = await getApplicationSupportDirectory();
    final cookieJar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage('${supportDir.path}/wave_cookies'),
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: appConfig.baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 18),
        sendTimeout: const Duration(seconds: 18),
        responseType: ResponseType.json,
        headers: const {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        validateStatus: (status) => status != null,
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));
    appConfig.addListener(() {
      dio.options.baseUrl = appConfig.baseUrl;
    });

    return ApiClient._(
      appConfig: appConfig,
      dio: dio,
      cookieJar: cookieJar,
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _request(method: 'PUT', path: path, data: data);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _request(method: 'PATCH', path: path, data: data);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _request(method: 'DELETE', path: path, data: data);
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.request<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(method: method),
    );

    final payload = response.data is Map<String, dynamic>
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};

    final statusCode = response.statusCode ?? 500;
    if (statusCode >= 200 && statusCode < 300) {
      return payload;
    }

    throw ApiException(
      message: payload['error'] as String? ?? 'Ошибка запроса',
      statusCode: statusCode,
    );
  }

  Future<String> cookieHeader() async {
    final cookies = await _cookieJar.loadForRequest(appConfig.baseUri);
    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }
}

class ApiException implements Exception {
  ApiException({
    required this.message,
    required this.statusCode,
  });

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
