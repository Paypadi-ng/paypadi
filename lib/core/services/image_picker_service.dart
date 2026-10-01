import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';
import 'package:paypadi/core/api/exceptions/client_exception.dart';

class ImagePickerService {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const int _maxFileSizeBytes = 10 * 1024 * 1024;

  final ImagePicker _picker;

  bool _isPicking = false;

  Future<File> pickImage({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) => _pick(
    ImageSource.gallery,
    imageQuality: imageQuality,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );

  Future<File> captureImage({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) => _pick(
    ImageSource.camera,
    imageQuality: imageQuality,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );

  Future<File> _pick(
    ImageSource source, {
    required int? imageQuality,
    required double? maxWidth,
    required double? maxHeight,
  }) async {
    assert(
      imageQuality == null || (imageQuality >= 0 && imageQuality <= 100),
      'imageQuality must be 0–100',
    );

    if (_isPicking) {
      throw const ClientException(
        message: 'Image picker is already in progress',
      );
    }

    _isPicking = true;
    try {
      final XFile? result = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (result == null) {
        throw const PickCancelledException('Cancelled image selection');
      }

      final int size = await result.length();
      if (size > _maxFileSizeBytes) {
        throw const ClientException(message: 'Image exceeds 10MB limit');
      }

      return File(result.path);
    } on ClientException {
      rethrow;
    } on PlatformException catch (pe) {
      throw ClientException(
        message: 'Platform error ${pe.code}: ${pe.message ?? pe.details ?? ''}',
        cause: pe,
      );
    } finally {
      _isPicking = false;
    }
  }
}
