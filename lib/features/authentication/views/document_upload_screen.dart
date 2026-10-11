import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/app/theme.dart';
import 'package:paypadi/core/utils/constants.dart' show Values;
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/features/authentication/controllers/file_upload_controller.dart';
import 'package:paypadi/gen/assets.gen.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';

@RoutePage()
class DocumentUploadScreen extends HookConsumerWidget {
  const DocumentUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formRef = useRef(GlobalKey<FormState>());

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          'Step 4 out of 5',
          style: context.textTheme.titleSmall,
        ),
        centerTitle: true,
      ),

      child: Form(
        key: formRef.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Values.v32.verticalSpace,
            Text(
              'Document Upload',
              style: context.textTheme.headlineMedium,
            ),
            Values.v16.verticalSpace,
            Text(
              'Kindly upload the documents needed to help give you the best experience.',
              style: context.textTheme.bodyMedium,
            ),
            Values.v32.verticalSpace,
            const _DocumentUploadWidget(
              documentCategory: DocumentCategory.driverLicenseFront,
            ),
            Values.v12.verticalSpace,
            const _DocumentUploadWidget(
              documentCategory: DocumentCategory.driverLicenseBack,
            ),
            Values.v12.verticalSpace,
            const _DocumentUploadWidget(
              documentCategory: DocumentCategory.vehicleLicense,
            ),
            Values.v24.verticalSpace,
            FilledButton(
              onPressed: () => submit(ref, formRef.value),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  void submit(WidgetRef ref, GlobalKey<FormState> form) {
    final allUploaded = DocumentCategory.values.every(
      (category) =>
          ref.read(fileUploadControllerProvider)[category]?.status ==
          UploadStatus.complete,
    );

    if (!allUploaded) {
      ref.showErrorToast('Please upload all documents before continuing.');
      return;
    }

    unawaited(ref.read(appRouterProvider).push(const PayoutAccountRoute()));
  }
}

class _DocumentUploadWidget extends ConsumerWidget {
  const _DocumentUploadWidget({required this.documentCategory});
  final DocumentCategory documentCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(fileUploadControllerProvider);
    final hasPickedFile = uploadState[documentCategory]?.file != null;

    return Column(
      spacing: Values.v4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          documentCategory.title,
          style: context.textTheme.bodyLarge,
        ),
        AnimatedSwitcher(
          duration: Durations.medium4,
          child: !hasPickedFile
              ? _FilePickerWidget(onPressed: () => pickFile(ref))
              : _UploadFileWidget(documentCategory: documentCategory),
        ),
      ],
    );
  }

  Future<void> pickFile(WidgetRef ref) async {
    await ref
        .read(filePickerControllerProvider.notifier)
        .pickFile(documentCategory);

    // Fresh read after await
    final freshFile = ref.read(filePickerControllerProvider);
    if (!freshFile.hasValue || freshFile.value?[documentCategory] == null) {
      return;
    }

    // Trigger upload immediately after picking
    await ref
        .read(fileUploadControllerProvider.notifier)
        .upload(documentCategory);
  }
}

class _FilePickerWidget extends ConsumerWidget {
  const _FilePickerWidget({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: context.screenWidth,
        padding: const EdgeInsets.symmetric(
          vertical: Values.v16,
          horizontal: Values.v24,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: context.palette.grey200),
          borderRadius: BorderRadius.circular(Values.v12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(Values.v10),
              decoration: BoxDecoration(
                color: context.palette.surface,
                border: Border.all(color: context.palette.grey300),
                borderRadius: BorderRadius.circular(Values.v8),
                boxShadow: [
                  BoxShadow(
                    blurRadius: Values.v2,
                    offset: const Offset(Values.zero, Values.v1),
                    color: context.palette.boxShadow.withValues(alpha: .05),
                  ),
                  BoxShadow(
                    offset: const Offset(Values.zero, Values.v2),
                    color: context.palette.boxShadow.withValues(alpha: .05),
                  ),
                ],
              ),
              // child: const Icon(EvaIcons.cloud_upload_outline),
            ),
            Values.v4.verticalSpace,
            RichText(
              text: TextSpan(
                text: 'Click to upload ',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: ref.watch(appPrimaryColorProvider),
                ),
                children: [
                  TextSpan(
                    text: 'or drag and drop',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.palette.grey600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Values.v4.verticalSpace,
            Text(
              'PDF, PNG, or JPG (max. 800x400px)',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.palette.grey600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadFileWidget extends HookConsumerWidget {
  const _UploadFileWidget({required this.documentCategory});
  final DocumentCategory documentCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileUploadControllerProvider);
    final fileName = state[documentCategory]?.file?.path.split('/').last ?? '';
    final extension = fileName.split('.').last.toUpperCase();
    final isFailed = state[documentCategory]?.status == UploadStatus.failed;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: Values.v16,
            horizontal: Values.v24,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isFailed
                  ? context.palette.failure
                  : context.palette.grey200,
            ),
            borderRadius: BorderRadius.circular(Values.v12),
          ),
          child: Row(
            spacing: Values.v12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                switch (extension) {
                  'PDF' => AppAssets.icons.icPdfFile.path,
                  'PNG' => AppAssets.icons.icPngFile.path,
                  'JPG' => AppAssets.icons.icJpgFile.path,
                  _ => AppAssets.icons.icBackspace.path,
                },
              ),
              _FileUploadWidget(documentCategory: documentCategory),
            ],
          ),
        ),
        Positioned(
          top: Values.v8,
          right: Values.v8,
          child: GestureDetector(
            onTap: () {
              ref
                  .read(fileUploadControllerProvider.notifier)
                  .reset(documentCategory);
            },
            // child: const Icon(
            //   EvaIcons.trash_2_outline,
            //   color: context.palette.grey400,
            // ),
          ),
        ),
      ],
    );
  }
}

class _FileUploadWidget extends HookConsumerWidget {
  const _FileUploadWidget({required this.documentCategory});
  final DocumentCategory documentCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileUploadControllerProvider);
    final fileName = state[documentCategory]?.file?.path.split('/').last ?? '';
    final primaryColor = ref.watch(appPrimaryColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fileName,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.palette.grey700,
          ),
        ),

        Row(
          spacing: Values.v4,
          children: [
            Text(
              state[documentCategory]?.formattedProgress ?? '0B of 0B',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.palette.grey600,
              ),
            ),
            Text(
              ' | ',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.palette.grey300,
              ),
            ),
            _FileUploadStatusWidget(
              uploadStatus: state[documentCategory]?.status,
            ),
          ],
        ),
        if (state[documentCategory]?.status == UploadStatus.uploading) ...[
          Values.v4.verticalSpace,
          Row(
            spacing: Values.v12,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: context.screenWidth * .54,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state[documentCategory]?.progress,
                    minHeight: Values.v8,
                    backgroundColor: context.palette.grey200,
                    valueColor: AlwaysStoppedAnimation(
                      primaryColor,
                    ),
                  ),
                ),
              ),
              Text(
                '${((state[documentCategory]?.progress ?? 0) * 100).toInt()}%',
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
        ] else if (state[documentCategory]?.status == UploadStatus.failed) ...[
          Values.v4.verticalSpace,
          GestureDetector(
            onTap: () => retry(ref),
            child: Text(
              'Try again',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.palette.failure,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void retry(WidgetRef ref) {
    unawaited(
      ref.read(fileUploadControllerProvider.notifier).retry(documentCategory),
    );
  }
}

class _FileUploadStatusWidget extends StatelessWidget {
  const _FileUploadStatusWidget({required this.uploadStatus});
  final UploadStatus? uploadStatus;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (uploadStatus) {
      UploadStatus.uploading => 'Uploading...',
      UploadStatus.complete => 'Complete',
      UploadStatus.failed => 'Failed',
      _ => '',
    };

    return Row(
      spacing: Values.v4,
      children: [
        // switch (uploadStatus) {
        //   UploadStatus.uploading => const Icon(
        //     EvaIcons.cloud_upload_outline,
        //     color: context.palette.grey500,
        //   ),
        //   UploadStatus.complete => const Icon(
        //     EvaIcons.checkmark_circle,
        //     color: context.palette.success,
        //   ),
        //   UploadStatus.failed => const Icon(
        //     Iconsax.close_circle_outline,
        //     size: Values.v16,
        //     color: context.palette.failure,
        //   ),
        //   _ => const SizedBox.shrink(),
        // },
        if (statusText.isNotEmpty)
          Text(
            statusText,
            style: context.textTheme.bodyMedium?.copyWith(
              color: switch (uploadStatus) {
                UploadStatus.uploading => context.palette.grey500,
                UploadStatus.complete => context.palette.success,
                UploadStatus.failed => context.palette.failure,
                _ => context.palette.grey500,
              },
            ),
          ),
      ],
    );
  }
}
