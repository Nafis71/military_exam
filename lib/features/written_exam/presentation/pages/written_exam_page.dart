import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/document_edge_detection_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../controllers/written_exam_controller.dart';
import '../widgets/written_exam_header.dart';
import '../widgets/written_exam_image_added_toast.dart';
import '../widgets/written_exam_info_banner.dart';
import '../widgets/written_exam_question_card.dart';
import '../widgets/written_exam_submit_image_dialog.dart';
import '../widgets/written_exam_upload_progress_overlay.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (sessionController.currentExam.value == null) {
        await sessionController.loadCurrentExam();
      }
    });
  }

  Future<void> _captureImage({required String questionId}) async {
    if (controller.imagesForQuestion(questionId).any(
      (img) => img.uploadStatus == ImageUploadStatus.uploaded,
    )) {
      return;
    }

    final cameraPermission = Get.find<CameraPermissionService>();
    final documentScan = Get.find<DocumentEdgeDetectionService>();
    final watchdog = Get.find<SecurityWatchdogService>();

    if (!await cameraPermission.isGranted) {
      controller.errorMessage.value = AppStrings.cameraPermissionRequired;
      return;
    }

    watchdog.setCameraCaptureActive(true);
    try {
      final scannedPath = await documentScan.scanDocument();
      if (scannedPath == null || !mounted) return;

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/written_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(scannedPath).copy(filePath);
      if (!mounted) return;

      final approved = await WrittenExamSubmitImageDialog.show(
        context: context,
        imagePath: filePath,
      );
      if (!mounted) return;

      if (approved != true) {
        await File(filePath).delete();
        return;
      }

      await controller.stageLocalImage(questionId, filePath);
      if (!mounted) return;

      final uploaded = await controller.uploadStagedImage(
        questionId: questionId,
        localPath: filePath,
      );
      if (!mounted) return;

      if (uploaded) {
        WrittenExamImageAddedToast.show();
      } else {
        await controller.removeLocalImage(
          controller.imagesForQuestion(questionId).last.localId,
        );
      }
    } finally {
      watchdog.setCameraCaptureActive(false);
    }
  }

  Future<void> _submitWritten() async {
    final question = controller.currentQuestion;
    if (question != null && !controller.currentQuestionHasUploadedImage) {
      controller.errorMessage.value =
          AppStrings.writtenExamRequireUploadedImage;
      return;
    }

    controller.submissionStatus.value = SubmissionStatus.saving;
    final examName = sessionController.currentExam.value?.examName ??
        AppStrings.finishExamDefaultName;
    final success = await sessionController.finalizeExamAndClearLocal();
    controller.submissionStatus.value =
        success ? SubmissionStatus.submitted : SubmissionStatus.failed;

    if (!success) {
      controller.errorMessage.value =
          sessionController.errorMessage.value ??
              AppStrings.somethingWentWrong;
      return;
    }

    final submittedAt =
        sessionController.submissionReceipt.value?.submittedAt ?? DateTime.now();
    Get.offAllNamed(
      AppRoutes.finishExam,
      arguments: <String, dynamic>{
        'examName': examName,
        'submittedAt': submittedAt,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExamConnectivitySnackBarListener(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Obx(() {
            if (!sessionController.canAccessQuestions.value) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
                  child: Text(
                    AppStrings.cannotAccessQuestions,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ),
              );
            }

            final question = controller.currentQuestion;
            final questionImages = question != null
                ? controller.imagesForQuestion(question.id)
                : <WrittenAnswerImage>[];
            final hasUploaded = questionImages.any(
              (img) => img.uploadStatus == ImageUploadStatus.uploaded,
            );

            return Stack(
              children: [
                Column(
                  children: [
                    WrittenExamHeader(
                      questionIndex: question?.index ?? 0,
                      questionTotal: question?.total ?? 0,
                      formattedTimer:
                          sessionController.timer.value?.formatted ?? '--:--',
                    ),
                    Expanded(
                      child: question == null
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md.w,
                                ),
                                child: Text(
                                  AppStrings.noQuestionsAvailable,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                20.w,
                                20.h,
                                20.w,
                                AppSpacing.lg.h,
                              ),
                              child: Column(
                                children: [
                                  if (!controller.hasAnyImages) ...[
                                    const WrittenExamInfoBanner(),
                                    SizedBox(height: 16.h),
                                  ],
                                  WrittenExamQuestionCard(
                                    question: question,
                                    images: questionImages,
                                    isLocked: hasUploaded,
                                    onAddImage: () => _captureImage(
                                      questionId: question.id,
                                    ),
                                    onReplace: (_) {},
                                    onDelete: (_) {},
                                  ),
                                  if (controller.errorMessage.value != null) ...[
                                    SizedBox(height: 12.h),
                                    Text(
                                      controller.errorMessage.value!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                    _WrittenNavigationBar(
                      controller: controller,
                      canSubmitExam: sessionController.canSubmitExam.value,
                      onSubmit: _submitWritten,
                    ),
                  ],
                ),
                if (controller.isUploading.value)
                  WrittenExamUploadProgressOverlay(
                    progress: controller.uploadProgress.value,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _WrittenNavigationBar extends StatelessWidget {
  const _WrittenNavigationBar({
    required this.controller,
    required this.canSubmitExam,
    required this.onSubmit,
  });

  final WrittenExamController controller;
  final bool canSubmitExam;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md.w + mediaPadding.left,
        17.h,
        AppSpacing.md.w + mediaPadding.right,
        16.h + mediaPadding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cF7FAF8,
        border: Border(top: BorderSide(color: AppColors.cD9E5DE)),
      ),
      child: Obx(() {
        final isLast = controller.isLastQuestion;
        final isSaving =
            controller.submissionStatus.value == SubmissionStatus.saving;

        return AppPrimaryButton(
          label: isLast
              ? AppStrings.submitWrittenExam
              : AppStrings.nextQuestion,
          isLoading: isSaving,
          onPressed: isLast
              ? (controller.canSubmit && canSubmitExam && !isSaving
                  ? onSubmit
                  : null)
              : (isSaving || controller.isUploading.value
                  ? null
                  : () async {
                      await controller.goToNext();
                    }),
        );
      }),
    );
  }
}
