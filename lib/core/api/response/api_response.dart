import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

@Freezed(genericArgumentFactories: true)
sealed class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool status,
    required String message,
    required T data,
  }) = _ApiResponse;

  factory ApiResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}

@Freezed(genericArgumentFactories: true)
sealed class ApiListResponse<T> with _$ApiListResponse<T> {
  const factory ApiListResponse({
    required bool status,
    required String message,
    required List<T> data,
  }) = _ApiListResponse;

  factory ApiListResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiListResponseFromJson(json, fromJsonT);
}

@Freezed(genericArgumentFactories: true)
sealed class PaginatedListResponse<T> with _$PaginatedListResponse<T> {
  const factory PaginatedListResponse({
    required int count,
    required List<T> results,
    String? next,
    String? previous,
  }) = _PaginatedListResponse;

  factory PaginatedListResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) => _$PaginatedListResponseFromJson(json, fromJsonT);
}
