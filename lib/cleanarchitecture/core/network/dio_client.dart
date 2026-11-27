import 'package:dio/dio.dart';

///test
class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late final Dio dio;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://m-techinnovations.co.in:8199/MAP/API/',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }
}

class DioClientnew {
  static final DioClientnew _instancenew = DioClientnew._internal();

  factory DioClientnew() => _instancenew;

  late final Dio dionew;

  DioClientnew._internal() {
    dionew = Dio(
      BaseOptions(
        baseUrl: 'http://m-techinnovations.co.in:8199/TLSKD/API/',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    dionew.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }
}
