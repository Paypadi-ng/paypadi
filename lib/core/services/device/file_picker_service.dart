import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:paypadi/core/api/exceptions/client_exception.dart';

class FilePickerService {
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;
  static const List<String> _allowedExtensions = ['jpg', 'pdf', 'png', 'jpeg'];

  Future<File> pickFileFromSystem() async {
    try {
      final PlatformFile? result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (result == null) {
        throw const PickCancelledException('Cancelled file upload');
      }

      // The size the picker reported, or read from disk if it didn't report
      // one.
      final size = result.size > 0 ? result.size : await result.length();
      if (size > _maxFileSizeBytes) {
        throw const ClientException(message: 'File exceeds 5MB limit');
      }

      return File(result.xFile.path);
    } on ClientException {
      rethrow;
    } on PlatformException catch (pe) {
      throw ClientException(
        message: 'Platform error ${pe.code}: ${pe.message ?? pe.details ?? ''}',
        cause: pe,
      );
    }
  }
}
