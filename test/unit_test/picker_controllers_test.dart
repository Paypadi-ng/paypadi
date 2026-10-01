import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:paypadi/core/services/file_picker_service.dart';
import 'package:paypadi/core/services/image_picker_service.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/src/features/authentication/controller/file_upload_controller.dart';
import 'package:paypadi/src/features/settings/controller/profile_picture_controller.dart';

/// Hands back the queued results in order; `null` means the user cancelled.
class _QueuedFilePicker extends FilePickerService {
  _QueuedFilePicker(this._results);
  final List<File?> _results;

  @override
  Future<File> pickFileFromSystem() async {
    final next = _results.removeAt(0);
    if (next == null) {
      throw const PickCancelledException('Cancelled file upload');
    }
    return next;
  }
}

class _QueuedImagePicker extends ImagePickerService {
  _QueuedImagePicker(this._results);
  final List<File?> _results;

  @override
  Future<File> pickImage({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final next = _results.removeAt(0);
    if (next == null) {
      throw const PickCancelledException('Cancelled image selection');
    }
    return next;
  }
}

void main() {
  group('FilePickerController.pickFile', () {
    test('keeps the previously picked file when the user cancels', () async {
      final licence = File('/tmp/licence-front.jpg');
      final container = ProviderContainer(
        overrides: [
          filePickerServiceProvider.overrideWithValue(
            _QueuedFilePicker([licence, null]),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(filePickerControllerProvider, (_, _) {});
      final controller = container.read(filePickerControllerProvider.notifier);

      await controller.pickFile(DocumentCategory.driverLicenseFront);
      await controller.pickFile(DocumentCategory.driverLicenseFront);

      final files = container.read(filePickerControllerProvider).value!;
      expect(files[DocumentCategory.driverLicenseFront], licence);
    });
  });

  group('ProfilePicture.uploadPicture', () {
    ProviderContainer containerWith(List<File?> picks) {
      final container = ProviderContainer(
        overrides: [
          imagePickerServiceProvider.overrideWithValue(
            _QueuedImagePicker(picks),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(profilePictureProvider, (_, _) {});
      return container;
    }

    test(
      'stays idle instead of loading forever when the user cancels',
      () async {
        final container = containerWith([null]);

        await container.read(profilePictureProvider.notifier).uploadPicture();

        final state = container.read(profilePictureProvider);
        expect(state.isLoading, isFalse);
        expect(state.value, isNull);
      },
    );

    test('holds the picked image', () async {
      final avatar = File('/tmp/avatar.jpg');
      final container = containerWith([avatar]);

      await container.read(profilePictureProvider.notifier).uploadPicture();

      expect(container.read(profilePictureProvider).value, avatar);
    });
  });
}
