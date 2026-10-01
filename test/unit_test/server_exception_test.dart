import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';

ServerException _handle(int status, Object? body) =>
    ServerException.handleResponse(
      Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: status,
        data: body,
      ),
    );

void main() {
  group('ServerException.handleResponse', () {
    test('uses a plain message', () {
      expect(
        _handle(400, {'status': false, 'message': 'Insufficient funds'}),
        const ServerException.badRequest('Insufficient funds'),
      );
    });

    test('reads the first message from field errors instead of throwing', () {
      expect(
        _handle(400, {
          'message': {
            'phone_number': ['This field is required.'],
          },
        }),
        const ServerException.badRequest('This field is required.'),
      );
      expect(
        _handle(422, {
          'message': ['Amount must be positive.'],
        }),
        const ServerException.unprocessableEntity('Amount must be positive.'),
      );
    });

    test(
      'falls back to the default text when there is no readable message',
      () {
        expect(
          _handle(400, {'message': 42}),
          const ServerException.badRequest(null),
        );
        expect(_handle(404, 'Not Found'), const ServerException.notFound(null));
      },
    );

    test('tolerates a data field that is not a map', () {
      expect(
        _handle(409, {
          'message': 'Already exists',
          'data': ['doc_1'],
        }),
        const ServerException.conflict('Already exists', null),
      );
      expect(
        _handle(409, {
          'message': 'Already exists',
          'data': {'document_id': 7},
        }),
        const ServerException.conflict('Already exists', '7'),
      );
    });
  });
}
