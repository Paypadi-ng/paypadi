part of 'file_upload_controller.dart';

class UploadState {
  const UploadState({
    this.status = UploadStatus.idle,
    this.sentBytes = 0,
    this.totalBytes = 0,
    this.file,
  });

  final int sentBytes;
  final int totalBytes;
  final File? file;
  final UploadStatus status;

  double get progress => totalBytes == 0 ? 0 : sentBytes / totalBytes;

  String get formattedProgress =>
      '${_formatBytes(sentBytes)} of ${_formatBytes(totalBytes)}';

  UploadState copyWith({
    UploadStatus? status,
    int? sentBytes,
    int? totalBytes,
    File? file,
  }) => UploadState(
    status: status ?? this.status,
    sentBytes: sentBytes ?? this.sentBytes,
    totalBytes: totalBytes ?? this.totalBytes,
    file: file ?? this.file,
  );
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
