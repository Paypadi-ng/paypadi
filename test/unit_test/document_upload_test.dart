import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/services/device/file_picker_service.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/profile/i_profile_repository.dart';
import 'package:paypadi/data/profile/models/user_profile_model.dart';
import 'package:paypadi/data/profile/providers.dart';
import 'package:paypadi/features/authentication/controllers/file_upload_controller.dart';

import '../helpers/transfer_fakes.dart';

class _QueuedFilePicker extends FilePickerService {
  _QueuedFilePicker(this._files);
  final List<File> _files;

  @override
  Future<File> pickFileFromSystem() async => _files.removeAt(0);
}

class _FakeProfileRepository implements IProfileRepository {
  @override
  FutureResultOf<ApiResponse<DriverProfileModel>> uploadDocument({
    required File file,
    required String fileName,
    required DocumentCategory category,
    required void Function(int, int)? onSendProgress,
  }) async => success(
    ok(
      const DriverProfileModel(
        id: 1,
        totalRides: 0,
        isApproved: false,
        isAvailable: false,
        submittedForApproval: false,
        createdAt: '2026-10-01T09:00:00Z',
        updatedAt: '2026-10-01T09:00:00Z',
      ),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test('a re-picked document starts over instead of keeping the old upload '
      'status', () async {
    final dir = await Directory.systemTemp.createTemp('document_upload_test');
    addTearDown(() => dir.delete(recursive: true));
    final first = File('${dir.path}/front-old.jpg')..writeAsBytesSync([1]);
    final second = File('${dir.path}/front-new.jpg')..writeAsBytesSync([2]);

    final container = ProviderContainer(
      overrides: [
        filePickerServiceProvider.overrideWithValue(
          _QueuedFilePicker([first, second]),
        ),
        profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(fileUploadControllerProvider, (_, _) {});
    const front = DocumentCategory.driverLicenseFront;
    UploadState frontState() =>
        container.read(fileUploadControllerProvider)[front]!;

    await container.read(filePickerControllerProvider.notifier).pickFile(front);
    await container.read(fileUploadControllerProvider.notifier).upload(front);
    expect(frontState().status, UploadStatus.complete);

    await container.read(filePickerControllerProvider.notifier).pickFile(front);

    expect(frontState().file?.path, second.path);
    expect(frontState().status, UploadStatus.idle);
  });
}
