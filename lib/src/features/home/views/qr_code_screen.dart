import 'dart:ui' as ui;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:paypadi/config/gen/assets.gen.dart';
import 'package:paypadi/config/gen/colors.gen.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/features/home/controller/qr_code_controller.dart';
import 'package:paypadi/src/shared/controllers/asset_share/asset_share_controller.dart';
import 'package:paypadi/src/shared/controllers/user_profile/user_profile_controller.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class QrCodeScreen extends StatefulHookConsumerWidget {
  const QrCodeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  late final QrCode _qrCode;
  late final QrImage _qrImage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileProvider);
    _qrCode = QrCode.fromData(
      data:
          '${user.value?.firstName} ${user.value?.lastName} '
          '\n${user.value?.phoneNumber.substring(4)}',
      errorCorrectLevel: QrErrorCorrectLevel.L,
    );
    _qrImage = QrImage(_qrCode);
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = useState<bool>(false);

    return AppScaffold(
      showAppBar: false,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CloseButton(),
              if (isScanning.value)
                IconButton(
                  onPressed: ref
                      .read(qrCodeControllerProvider.notifier)
                      .toggleTorch,
                  icon: const Icon(Icons.flashlight_on_outlined),
                )
              else
                IconButton(
                  onPressed: () async => _share(),
                  icon: AppAssets.icons.icShare.svg(),
                ),
            ],
          ),
          const Spacer(),
          Center(
            child: AnimatedSwitcher(
              duration: Durations.medium2,
              child: isScanning.value ? const _ScanQrCode() : _GenerateQrCode(),
            ),
          ),
          const Spacer(),
          _ScanPageActions(inScanMode: isScanning),
          Values.v32.verticalSpace,
        ],
      ),
    );
  }

  Future<void> _share() async {
    // 1. Generate the QR code as a raw ui.Image (instead of ByteData)
    final image = await _qrImage.toImage(
      size: 512,
      configuration: ImageConfiguration(
        devicePixelRatio: context.devicePixelRatio,
        size: const Size.square(Values.v120 * 2.5),
      ),
      decoration: PrettyQrDecoration(
        background: AppColors.white,
        image: PrettyQrDecorationImage(
          image: AssetImage(AppAssets.images.appLogo.path),
        ),
      ),
    );

    // 2. Define your desired padding
    // (You can also use your Values class here, e.g., Values.v32)
    const double padding = 128.0;

    // Calculate the new total canvas size
    final int paddedWidth = (image.width + (padding * 2)).toInt();
    final int paddedHeight = (image.height + (padding * 2)).toInt();

    // 3. Set up a custom canvas to draw the background and padding
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Draw the white background first (so the padding isn't transparent)
    final bgPaint = ui.Paint()..color = AppColors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, paddedWidth.toDouble(), paddedHeight.toDouble()),
      bgPaint,
    );

    // Draw the generated QR code directly in the center of the white background
    canvas.drawImage(image, const ui.Offset(padding, padding), ui.Paint());

    // 4. Render the newly padded canvas into a final image
    final paddedPicture = recorder.endRecording();
    final finalImage = await paddedPicture.toImage(paddedWidth, paddedHeight);

    // 5. Extract the raw Uint8List bytes as PNG
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) return;

    final bytes = byteData.buffer.asUint8List();

    // 6. Share
    await ref.read(assetShareControllerProvider.notifier).shareQrCode(bytes);
  }
}

class _ScanPageActions extends StatelessWidget {
  const _ScanPageActions({required this.inScanMode});
  final ValueNotifier<bool> inScanMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        border: BoxBorder.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(Values.v8),
      ),
      child: ValueListenableBuilder(
        valueListenable: inScanMode,
        builder: (context, scanValue, _) {
          return Row(
            mainAxisSize: .min,
            children: [
              GestureDetector(
                onTap: () => inScanMode.value = true,
                child: AnimatedContainer(
                  duration: Durations.long4,
                  padding: const EdgeInsets.symmetric(
                    vertical: Values.v12,
                    horizontal: Values.v36,
                  ),
                  decoration: BoxDecoration(
                    color: scanValue ? AppColors.white : AppColors.grey50,
                    borderRadius: BorderRadius.circular(Values.v8),
                    border: scanValue
                        ? BoxBorder.all(color: AppColors.grey300)
                        : null,
                  ),
                  child: Text('Scan', style: context.textTheme.bodyMedium),
                ),
              ),
              GestureDetector(
                onTap: () => inScanMode.value = false,
                child: AnimatedContainer(
                  duration: Durations.long4,
                  padding: const EdgeInsets.symmetric(
                    vertical: Values.v12,
                    horizontal: Values.v36,
                  ),
                  decoration: BoxDecoration(
                    color: !scanValue ? AppColors.white : AppColors.grey50,
                    borderRadius: BorderRadius.circular(Values.v8),
                    border: !scanValue
                        ? BoxBorder.all(color: AppColors.grey300)
                        : null,
                  ),
                  child: Text('My code', style: context.textTheme.bodyMedium),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScanQrCode extends ConsumerWidget {
  const _ScanQrCode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref
        .watch(qrCodeControllerProvider.notifier)
        .scannerController;

    return Column(
      spacing: Values.v16,
      mainAxisSize: .min,
      children: [
        SizedBox.square(
          dimension: Values.v120 * 2.5,
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(Values.v24),
            child: MobileScanner(controller: controller),
          ),
        ),
        Text(
          'Scan QR code',
          style: context.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _GenerateQrCode extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);

    return Column(
      mainAxisAlignment: .center,
      children: [
        user.maybeWhen(
          data: (user) {
            return Column(
              spacing: Values.v16,
              children: [
                SizedBox.square(
                  dimension: Values.v120 * 2.5,
                  child: PrettyQrView.data(
                    data:
                        '${user?.firstName} ${user?.lastName} '
                        '\n${user?.phoneNumber.substring(4)}',
                    decoration: PrettyQrDecoration(
                      image: PrettyQrDecorationImage(
                        image: AssetImage(AppAssets.images.appLogo.path),
                      ),
                    ),
                  ),
                ),
                Text(
                  '${user?.firstName} ${user?.lastName}',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            );
          },
          loading: () => const Skeletonizer(
            child: SizedBox.square(dimension: Values.v120 * 2.5),
          ),
          error: (e, _) => Column(
            children: [
              Text(
                'Something went wrong. Retry!',
                style: context.textTheme.bodySmall,
              ),
              TextButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
          orElse: SizedBox.shrink,
        ),

        Text(
          'Scan to pay',
          style: context.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
