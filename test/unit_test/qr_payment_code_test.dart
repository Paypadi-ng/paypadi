import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/features/home/controllers/qr_code_controller.dart';
import 'package:paypadi/shared/controllers/app_toast_controller.dart';
import 'package:paypadi/shared/controllers/transfer_draft.dart';

import '../helpers/transfer_fakes.dart';

void main() {
  group('payment QR codes', () {
    test('carry the whole phone number', () {
      expect(
        paymentQrData(
          firstName: 'Ada',
          lastName: 'Obi',
          phoneNumber: '+2348031234567',
        ),
        'Ada Obi\n+2348031234567',
      );
    });

    test('read back the phone number they carry', () {
      expect(phoneFromPaymentQr('Ada Obi\n+2348031234567'), '+2348031234567');
      expect(phoneFromPaymentQr('Ada Obi\n08031234567'), '08031234567');
    });

    test('restore the leading 0 on codes made before this fix', () {
      expect(phoneFromPaymentQr('Ada Obi \n8031234567'), '08031234567');
    });

    test('reject codes that carry no phone number', () {
      expect(phoneFromPaymentQr('https://example.com'), isNull);
      expect(phoneFromPaymentQr('Ada Obi\n12345'), isNull);
    });
  });

  group('scanning', () {
    late PendingPushRouter router;
    late SilentToastController toasts;
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          appRouterProvider.overrideWith((ref) => PendingPushRouter(ref: ref)),
          appToastControllerProvider.overrideWith(SilentToastController.new),
        ],
      );
      addTearDown(container.dispose);
      router = container.read(appRouterProvider) as PendingPushRouter;
      toasts =
          container.read(appToastControllerProvider.notifier)
              as SilentToastController;
      container.listen(qrCodeControllerProvider, (_, _) {});
    });

    QrCodeController scanner() =>
        container.read(qrCodeControllerProvider.notifier);

    test('opens one transfer per code and scans again once the user comes '
        'back', () async {
      await container.read(qrCodeControllerProvider.future);

      scanner()
        ..handleScannedCode('Ada Obi\n08031234567')
        // The camera keeps reporting the code while the transfer opens.
        ..handleScannedCode('Ada Obi\n08031234567');

      expect(router.pushed, hasLength(1));
      expect(
        router.pushed.single,
        isA<TransferRoute>()
            .having((route) => route.args?.number, 'number', '08031234567')
            .having(
              (route) => route.args?.lookupBy,
              'lookupBy',
              LookupBy.phoneNumber,
            ),
      );

      router.closePushedScreen();
      await pumpEventQueue();
      scanner().handleScannedCode('Tunde Bello\n08099998888');

      expect(router.pushed, hasLength(2));
    });

    test('says once when a code is not a payment code', () async {
      await container.read(qrCodeControllerProvider.future);

      scanner()
        ..handleScannedCode('https://example.com')
        ..handleScannedCode('https://example.com');

      expect(router.pushed, isEmpty);
      expect(toasts.errors, ["This isn't a Paypadi payment code."]);
    });
  });
}
