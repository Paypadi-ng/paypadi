import 'dart:typed_data';

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'asset_share_controller.g.dart';

enum ShareStatus { idle, success, failed }

@riverpod
class AssetShareController extends _$AssetShareController {
  @override
  ShareStatus build() => ShareStatus.idle;

  Future<void> shareQrCode(Uint8List bytes) async {
    final service = ref.watch(assetShareServiceProvider);

    try {
      final shareResult = await service.shareBytes(
        bytes: bytes,
        fileName: 'payment_qr_code.png',
        mimeType: 'image/png',
        text: 'Scan to pay',
      );

      if (shareResult.status == ShareResultStatus.success) {
        state = ShareStatus.success;
      }
    } catch (e) {
      if (ref.mounted) state = ShareStatus.failed;
    }
  }
}
