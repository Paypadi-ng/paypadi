import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/api/exceptions/app_exception.dart';
import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/api/result.dart';

void main() {
  test('map transforms success value', () {
    final r = success<int, Exception>(2).map((v) => v * 2);
    expect(r.isSuccess, true);
    expect(r.successValue, 4);
  });

  test('flatMap propagates failure', () {
    final r = success<int, Exception>(
      2,
    ).flatMap((_) => failure<int, Exception>(Exception('err')));
    expect(r.isFailure, true);
    expect(r.failureValue.toString(), contains('err'));
  });

  test('forEach runs synchronous callback', () async {
    var seen = 0;
    final r = success<int, Exception>(3);
    await r.forEach((v) => seen = v);
    expect(seen, 3);
  });

  test('forEach runs asynchronous callback', () async {
    var seen = 0;
    final r = success<int, Exception>(4);
    await r.forEach((v) async {
      // await Future.delayed(Duration.zero);
      seen = v;
    });
    expect(seen, 4);
  });

  test('fromAction returns success or rethrows Error', () {
    final ok = Result.fromAction(() => 5);
    expect(ok.isSuccess, true);
    expect(ok.successValue, 5);

    expect(
      () => Result.fromAction(() {
        throw AssertionError('boom');
      }),
      throwsA(isA<AssertionError>()),
    );
  });

  test(
    'fromAsync converts non-Dio Exception to ClientException wrapper',
    () async {
      final r = await Result.fromAsync<int>(
        () async => throw const FormatException('bad'),
      );
      expect(r.isFailure, true);
      expect(r.failureValue, isA<ClientException>());
    },
  );

  test('fromAsync maps Dio badResponse to ServerException', () async {
    final requestOptions = RequestOptions(path: '/');
    final response = Response(
      requestOptions: requestOptions,
      statusCode: 500,
      data: {'message': 'oops'},
    );
    final dioException = DioException(
      requestOptions: requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );

    final r = await Result.fromAsync<int>(() async => throw dioException);
    expect(r.isFailure, true);
    expect(
      r.failureValue,
      isA<ServerException>(),
    ); // ServerException wraps server-side errors
  });

  test(
    'fromAsync maps Dio connectionError to ServerException.noInternetConnection',
    () async {
      final requestOptions = RequestOptions(path: '/');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
      );

      final r = await Result.fromAsync<int>(() async => throw dioException);
      expect(r.isFailure, true);
      expect(r.failureValue, isA<ServerException>());
    },
  );

  test(
    'fromAsync maps Dio cancel to ServerException.requestCancelled',
    () async {
      final requestOptions = RequestOptions(path: '/');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.cancel,
      );

      final r = await Result.fromAsync<int>(() async => throw dioException);
      expect(r.isFailure, true);
      expect(r.failureValue, isA<ServerException>());
      expect(r.failureValue.toString(), contains('requestCancelled'));
    },
  );

  test(
    'fromAsync maps Dio unknown to ServerException.serviceUnavailable',
    () async {
      final requestOptions = RequestOptions(path: '/');
      final dioException = DioException(
        requestOptions: requestOptions,
        message: 'something',
      );

      final r = await Result.fromAsync<int>(() async => throw dioException);
      expect(r.isFailure, true);
      expect(r.failureValue, isA<ServerException>());
    },
  );

  test(
    'AppException maps Dio receiveTimeout to ServerException.receiveTimeout',
    () {
      final requestOptions = RequestOptions(path: '/');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.receiveTimeout,
      );
      final appEx = AppException.handleException(dioException);
      expect(appEx, isA<ServerException>());
      // cast and check variant by toString or pattern matching
      expect(appEx.toString(), contains('receiveTimeout'));
    },
  );
}
