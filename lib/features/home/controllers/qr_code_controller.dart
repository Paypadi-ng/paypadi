import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/features/transfer/controllers/transfer_draft.dart';
import 'package:paypadi/shared/controllers/app_toast_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'qr_code_controller.g.dart';

/// The text in a user's payment QR code: their name, then their phone
/// number on its own line.
String paymentQrData({
  required String? firstName,
  required String? lastName,
  required String? phoneNumber,
}) => '${firstName ?? ''} ${lastName ?? ''}\n${phoneNumber ?? ''}';

/// The phone number in a scanned payment code, or null when the code
/// doesn't end with one.
///
/// Codes generated before this fix dropped the first four characters of the
/// number ("+2348031234567" became "8031234567"); those get their leading 0
/// back.
String? phoneFromPaymentQr(String rawCode) {
  final String last = rawCode.trim().split(RegExp(r'\s+')).last;
  final String number = last.replaceAll(RegExp(r'[^\d+]'), '');

  if (RegExp(r'^[789]\d{9}$').hasMatch(number)) return '0$number';
  if (RegExp(r'^(\+?234\d{10}|0\d{10})$').hasMatch(number)) return number;
  return null;
}

@riverpod
class QrCodeController extends _$QrCodeController {
  late MobileScannerController scannerController;
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

  /// Whether a scanned code is being handled, so the frames that keep
  /// arriving meanwhile are ignored.
  bool _isHandlingScan = false;

  /// The last code that wasn't a payment code, so it's only reported once.
  String? _lastRejectedCode;

  void _onBarcodeDetected(BarcodeCapture capture) {
    final String? rawCode = capture.barcodes.firstOrNull?.rawValue;
    if (rawCode != null) handleScannedCode(rawCode);
  }

  /// Opens a transfer to the phone number in a scanned payment code.
  ///
  /// Scanning resumes once the user comes back to this screen. Before, the
  /// barcode subscription was cancelled after the first scan, so the
  /// scanner stayed dead for as long as the screen was open.
  @visibleForTesting
  void handleScannedCode(String rawCode) {
    if (_isHandlingScan) return;

    final String? phoneNumber = phoneFromPaymentQr(rawCode);
    if (phoneNumber == null) {
      if (rawCode != _lastRejectedCode) {
        _lastRejectedCode = rawCode;
        ref
            .read(appToastControllerProvider.notifier)
            .showError("This isn't a Paypadi payment code.");
      }
      return;
    }

    _isHandlingScan = true;
    state = AsyncData(phoneNumber);
    ref.read(transferDraftControllerProvider.notifier).start();
    unawaited(_openTransfer(phoneNumber));
  }

  Future<void> _openTransfer(String phoneNumber) async {
    // push() completes when the transfer screen is popped, which is when
    // the user is back on this screen and can scan again.
    await ref
        .read(appRouterProvider)
        .push(
          TransferRoute(number: phoneNumber, lookupBy: LookupBy.phoneNumber),
        );

    if (!ref.mounted) return;
    _isHandlingScan = false;
    _lastRejectedCode = null;
    state = const AsyncData(null);
  }

  Future<void> toggleTorch() async {
    await scannerController.toggleTorch();
  }

  Future<void> switchCamera() async {
    await scannerController.switchCamera();
  }
}
