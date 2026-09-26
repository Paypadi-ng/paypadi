import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:paypadi/core/api/exceptions/client_exception.dart';

class FilePickerService {
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;
  static const List<String> _allowedExtensions = ['jpg', 'pdf', 'png', 'jpeg'];

  Future<PlatformFile> pickFileFromSystem() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (file == null) {
        throw const ClientException(message: 'Cancelled file upload');
      }

      final size = await file.length();
      if (size == null) {
        throw const ClientException(
          message: 'Could not read the selected file',
        );
      }
      if (size > _maxFileSizeBytes) {
        throw const ClientException(message: 'File exceeds 5MB limit');
      }

      return file;
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
