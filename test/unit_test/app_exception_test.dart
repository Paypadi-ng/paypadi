import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/api/exceptions/app_exception.dart';
import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';

void main() {
  group('AppException.handleException', () {
    test('maps a dio transform timeout to a receive timeout', () {
      final exception = AppException.handleException(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.transformTimeout,
        ),
      );

      expect(exception, const ServerException.receiveTimeout());
    });
  });

  group('PickCancelledException', () {
    const cancelled = PickCancelledException('Cancelled file upload');

    test('is a ClientException carrying its message', () {
      expect(cancelled, isA<ClientException>());
      expect(cancelled.message, 'Cancelled file upload');
    });

    test('is logged at info level and never reported', () {
      expect(cancelled.monitoringSeverity, SeverityLevel.info);
      expect(cancelled.isReportable, isFalse);
    });
  });
}
