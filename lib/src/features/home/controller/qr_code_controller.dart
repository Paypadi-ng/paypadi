import 'dart:async';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'qr_code_controller.g.dart';

@riverpod
class QrCodeController extends _$QrCodeController {
  late final MobileScannerController scannerController;
  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  @override
  FutureOr<String?> build() async {
    // 1. Initialize the MobileScannerController
    scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );

    // 2. Listen to the barcode stream
    _barcodeSubscription = scannerController.barcodes.listen(
      _onBarcodeDetected,
    );

    // 3. Manage Lifecycle
    ref.onDispose(() async {
      await _barcodeSubscription?.cancel();
      await scannerController.dispose();
    });

    return null;
  }

  /// Handles the incoming barcode capture events
  void _onBarcodeDetected(BarcodeCapture capture) {
    // GUARD: If we've already captured a value, completely ignore this frame.
    // This prevents the double-navigation bug.
    if (state.hasValue && state.value != null) return;

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      // 1. Immediately cancel the subscription so it stops listening entirely
      unawaited(_barcodeSubscription?.cancel());

      // 2. Extract and sanitize the raw code by removing the newline
      final String rawCode = barcodes.first.rawValue!;
      final String cleanCode = rawCode.replaceAll('\n', '');

      // Update state with the clean string
      state = AsyncData(cleanCode);

      // 3. Process and navigate
      // Splitting by \s+ handles any extra spaces left behind safely
      final numberParts = cleanCode.split(RegExp(r'\s+'));
      numberParts.printLog();

      unawaited(
        ref
            .read(appRouterProvider)
            .push(TransferRoute(number: numberParts.last)),
      );
    }
  }

  Future<void> toggleTorch() async {
    await scannerController.toggleTorch();
  }

  Future<void> switchCamera() async {
    await scannerController.switchCamera();
  }
}
