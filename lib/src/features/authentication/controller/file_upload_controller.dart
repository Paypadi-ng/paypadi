import 'dart:io';

import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/data/profile/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_upload_controller.g.dart';
part 'upload_state.dart';

@riverpod
class FilePickerController extends _$FilePickerController {
  @override
  AsyncValue<Map<DocumentCategory, File?>> build() => AsyncData(_default);

  Future<void> pickFile(DocumentCategory documentCategory) async {
    try {
      final file = await ref
          .read(filePickerServiceProvider)
          .pickFileFromSystem();

      if (!ref.mounted) return;

      final updated = Map<DocumentCategory, File?>.from(
        state.value ?? _default,
      );
      updated[documentCategory] = file;

      state = AsyncData(updated);
    } on PickCancelledException {
      // The user backed out of the picker; keep whatever was picked before.
      return;
    } on ClientException catch (e) {
      if (!ref.mounted) return;

      ref.showExceptionMessage(e);

      // Only clear the failed category
      final current = Map<DocumentCategory, File?>.from(
        state.value ?? _default,
      );
      current[documentCategory] = null;

      state = AsyncData(current);
    }
  }

  void clearFile(DocumentCategory documentCategory) {
    final current = Map<DocumentCategory, File?>.from(
      state.value ?? _default,
    );
    current[documentCategory] = null;
    state = AsyncData(current);
  }

  final Map<DocumentCategory, File?> _default = <DocumentCategory, File?>{
    DocumentCategory.driverLicenseBack: null,
    DocumentCategory.driverLicenseFront: null,
    DocumentCategory.vehicleLicense: null,
  };
}

@riverpod
class FileUploadController extends _$FileUploadController {
  final Map<DocumentCategory, UploadState> _uploadStates =
      <DocumentCategory, UploadState>{};

  @override
  Map<DocumentCategory, UploadState> build() {
    final files = ref.watch(filePickerControllerProvider).value ?? {};

    return <DocumentCategory, UploadState>{
      for (final MapEntry(key: category, value: file) in files.entries)
        category: _syncedState(category, file),
    };
  }

  /// Keeps a category's upload progress while its file is unchanged. A newly
  /// picked or cleared file starts over at idle; before, a re-picked file
  /// kept the previous file's "complete" status and was never uploaded.
  UploadState _syncedState(DocumentCategory category, File? file) {
    final previous = _uploadStates[category];
    if (previous != null && previous.file?.path == file?.path) return previous;
    return _uploadStates[category] = UploadState(file: file);
  }

  Future<void> upload(DocumentCategory category) async {
    final file = state[category]?.file;
    if (file == null) return;

    _updateCategory(
      category,
      UploadState(
        status: UploadStatus.uploading,
        file: file,
        totalBytes: file.lengthSync(),
      ),
    );

    final result = await ref
        .read(profileRepositoryProvider)
        .uploadDocument(
          file: file,
          category: category,
          fileName: file.path.split('/').last,
          onSendProgress: (sent, total) => _updateCategory(
            category,
            _uploadStates[category]!.copyWith(
              sentBytes: sent,
              totalBytes: total,
            ),
          ),
        );

    result.fold(
      (success) => _updateCategory(
        category,
        _uploadStates[category]!.copyWith(status: UploadStatus.complete),
      ),
      (failure) {
        ref.showExceptionMessage(failure);
        _updateCategory(
          category,
          _uploadStates[category]!.copyWith(status: UploadStatus.failed),
        );
      },
    );
  }

  Future<void> retry(DocumentCategory category) => upload(category);

  void reset(DocumentCategory category) {
    _uploadStates.remove(category);
    ref.read(filePickerControllerProvider.notifier).clearFile(category);
    // Clearing the file triggers a picker rebuild, which drives build() again.
    // No need to manually update state here.
  }

  void _updateCategory(DocumentCategory category, UploadState uploadState) {
    _uploadStates[category] = uploadState;
    state = Map.from(state)..[category] = uploadState;
  }
}
