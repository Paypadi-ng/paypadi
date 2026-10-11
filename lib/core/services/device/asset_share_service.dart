import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class AssetShareService {
  /// Shares simple text or a URL.
  ///
  /// [text] The message or link to share.
  /// [subject] An optional email subject (where supported).
  /// [sharePositionOrigin] Required for iPads to anchor the share popover.
  Future<ShareResult> shareText({
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    final params = ShareParams(
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );

    return SharePlus.instance.share(params);
  }

  /// Shares a bundled local asset (e.g., an image from pubspec.yaml).
  ///
  /// [assetPath] The full path to the asset (e.g., 'assets/images/logo.png').
  /// [fileName] The name the file will have when shared (e.g., 'logo.png').
  /// [text] Optional accompanying text.
  /// [mimeType] Optional MIME type (e.g., 'image/png').
  Future<ShareResult> shareBundledAsset({
    required String assetPath,
    required String fileName,
    String? text,
    String? subject,
    String? mimeType,
    Rect? sharePositionOrigin,
  }) async {
    try {
      // 1. Load the raw bytes of the asset from the root bundle
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      // 2. Wrap the bytes into an XFile
      final file = XFile.fromData(
        bytes,
        mimeType: mimeType,
      );

      // 3. Share the file. Note: fileNameOverrides is crucial when using fromData
      final params = ShareParams(
        files: [file],
        fileNameOverrides: [fileName],
        text: text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      );

      return await SharePlus.instance.share(params);
    } catch (e) {
      debugPrint('Error sharing bundled asset: $e');
      return ShareResult('$text', ShareResultStatus.unavailable);
    }
  }

  /// Shares a file from the device's local file system (e.g., a downloaded/cached image).
  ///
  /// [filePath] The absolute path to the file.
  Future<ShareResult> shareSystemFile({
    required String filePath,
    String? text,
    String? subject,
    String? mimeType,
    Rect? sharePositionOrigin,
  }) async {
    final file = XFile(filePath, mimeType: mimeType);

    final params = ShareParams(
      files: [file],
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );

    return SharePlus.instance.share(params);
  }

  /// Shares a file directly from memory bytes (e.g., a generated QR code image).
  ///
  /// [bytes] The raw file data in memory.
  /// [fileName] The name the file will have when shared (e.g., 'qr_code.png').
  Future<ShareResult> shareBytes({
    required Uint8List bytes,
    required String fileName,
    String? text,
    String? subject,
    String? mimeType,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final file = XFile.fromData(
        bytes,
        mimeType: mimeType,
      );

      final params = ShareParams(
        files: [file],
        fileNameOverrides: [fileName],
        text: text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      );

      return await SharePlus.instance.share(params);
    } catch (e) {
      debugPrint('Error sharing memory file: $e');
      return ShareResult(text ?? '', ShareResultStatus.unavailable);
    }
  }
}
