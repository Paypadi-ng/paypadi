import 'dart:io';

import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/services/device/image_picker_service.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_picture_controller.g.dart';

@riverpod
class ProfilePicture extends _$ProfilePicture {
  late ImagePickerService _service;

  @override
  FutureOr<File?> build() {
    _service = ref.watch(imagePickerServiceProvider);
    return null;
  }

  Future<void> uploadPicture() async {
    final File image;
    try {
      image = await _service.pickImage();
    } on PickCancelledException {
      return;
    } on ClientException catch (e) {
      if (ref.mounted) ref.showExceptionMessage(e);
      return;
    }

    if (!ref.mounted) return;

    // NOTE: Complete this function: upload [image] once the endpoint exists.
    state = AsyncData(image);
  }
}
