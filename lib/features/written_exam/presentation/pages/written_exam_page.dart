import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../controllers/written_exam_controller.dart';

class WrittenExamPage extends StatefulWidget {
  const WrittenExamPage({super.key});

  @override
  State<WrittenExamPage> createState() => _WrittenExamPageState();
}

class _WrittenExamPageState extends State<WrittenExamPage> {
  late final WrittenExamController controller;
  late final ExamSessionController sessionController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<WrittenExamController>();
    sessionController = Get.find<ExamSessionController>();
  }

  Future<void> _captureImage({String? replaceLocalId}) async {
    final cameraPermission = Get.find<CameraPermissionService>();
    final watchdog = Get.find<SecurityWatchdogService>();

    if (!await cameraPermission.isGranted) {
      controller.errorMessage.value = AppStrings.cameraPermissionRequired;
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      controller.errorMessage.value = AppStrings.noCameraAvailable;
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    watchdog.setCameraCaptureActive(true);
    try {
      if (!mounted) return;

      final captured = await Navigator.of(context).push<XFile?>(
        MaterialPageRoute(
          builder: (_) => _CameraCapturePage(camera: camera),
          fullscreenDialog: true,
        ),
      );

      if (captured != null) {
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/written_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(captured.path).copy(filePath);
        if (replaceLocalId != null) {
          await controller.replaceImage(replaceLocalId, filePath);
        } else {
          await controller.addImage(filePath);
        }
      }
    } finally {
      watchdog.setCameraCaptureActive(false);
    }
  }

  Future<void> _submitWritten() async {
    final sessionId = sessionController.examSession.value?.sessionId;
    if (sessionId == null) return;

    await controller.submitExam(sessionId);
    if (controller.submissionStatus.value == SubmissionStatus.submitted) {
      await sessionController.finishExam();
      Get.offAllNamed(AppRoutes.finishExam);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExamConnectivitySnackBarListener(
      child: PopScope(
        canPop: false,
        child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppAppBar(
          title: AppStrings.writtenAnswers,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: _captureImage,
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: AppStrings.captureAnswerPageTooltip,
            ),
          ],
        ),
        body: Obx(() {
          return Column(
            children: [
              Expanded(
                child: controller.images.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg.w),
                          child: Text(
                            AppStrings.captureWrittenAnswersHint,
                            style: AppTypography.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(AppSpacing.lg.w),
                        itemCount: controller.images.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: AppSpacing.md.h),
                        itemBuilder: (context, index) {
                          final image = controller.images[index];
                          return _WrittenImageTile(
                            image: image,
                            onDelete: () => controller.deleteImage(image.localId),
                            onReplace: () =>
                                _captureImage(replaceLocalId: image.localId),
                          );
                        },
                      ),
              ),
              _WrittenSubmitBar(
                onSubmit: _submitWritten,
                isLoading:
                    controller.submissionStatus.value == SubmissionStatus.saving,
                canSubmit: controller.images.isNotEmpty,
                errorMessage: controller.errorMessage.value,
              ),
            ],
          );
        }),
        ),
      ),
    );
  }
}

class _CameraCapturePage extends StatefulWidget {
  const _CameraCapturePage({required this.camera});

  final CameraDescription camera;

  @override
  State<_CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<_CameraCapturePage> {
  CameraController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: AppColors.c000000,
      body: !_initialized || controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl.w),
                    child: FloatingActionButton.large(
                      onPressed: () async {
                        final file = await controller.takePicture();
                        if (context.mounted) Navigator.of(context).pop(file);
                      },
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _WrittenImageTile extends StatelessWidget {
  const _WrittenImageTile({
    required this.image,
    required this.onDelete,
    required this.onReplace,
  });

  final WrittenAnswerImage image;
  final VoidCallback onDelete;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.file(
            File(image.localPath),
            width: 56.w,
            height: 56.w,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(Icons.image, size: 56.w),
          ),
        ),
        title: Text(AppStrings.answerPage, style: AppTypography.labelLarge),
        subtitle: Text(
          image.uploadStatus.displayLabel,
          style: AppTypography.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onReplace,
              tooltip: AppStrings.replace,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: AppStrings.delete,
            ),
          ],
        ),
      ),
    );
  }
}

class _WrittenSubmitBar extends StatelessWidget {
  const _WrittenSubmitBar({
    required this.onSubmit,
    required this.isLoading,
    required this.canSubmit,
    this.errorMessage,
  });

  final VoidCallback onSubmit;
  final bool isLoading;
  final bool canSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
              child: Text(
                errorMessage!,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
              ),
            ),
          AppPrimaryButton(
            label: AppStrings.submitWrittenExam,
            isLoading: isLoading,
            onPressed: !canSubmit || isLoading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
