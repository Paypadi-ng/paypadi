import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:paypadi/core/services/image_picker_service.dart';

/// Returns [result] from every pick.
class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.result);
  final XFile? result;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => result;
}

void main() {
  test('throws PickCancelledException when the user backs out', () async {
    final service = ImagePickerService(picker: _FakeImagePicker(null));

    await expectLater(
      service.pickImage(),
      throwsA(isA<PickCancelledException>()),
    );
  });

  test('rejects images over 10MB', () async {
    final tooBig = XFile.fromData(
      Uint8List(10 * 1024 * 1024 + 1),
      path: 'big.jpg',
    );
    final service = ImagePickerService(picker: _FakeImagePicker(tooBig));

    await expectLater(
      service.pickImage(),
      throwsA(
        isA<ClientException>()
            .having((e) => e.message, 'message', 'Image exceeds 10MB limit')
            .having((e) => e, 'type', isNot(isA<PickCancelledException>())),
      ),
    );
  });

  test('returns the picked image as a File', () async {
    final dir = await Directory.systemTemp.createTemp('image_picker_test');
    addTearDown(() => dir.delete(recursive: true));
    final picked = File('${dir.path}/avatar.jpg')..writeAsBytesSync([1, 2, 3]);

    final service = ImagePickerService(
      picker: _FakeImagePicker(XFile(picked.path)),
    );

    expect((await service.pickImage()).path, picked.path);
  });
}
