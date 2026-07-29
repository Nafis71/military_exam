import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/services/document_edge_detection_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../core/widgets/exam_question_navigation_bar.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../../../security_gate/domain/usecases/check_connectivity_usecase.dart';
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
      final refreshFromApi = !Get.find<ExamRunContext>().isOnboardingDemo;
      await sessionController.loadCurrentExam(refresh: refreshFromApi);
      if (!sessionController.canAccessQuestions.value) {
        final sessionId =
            sessionController.examSession.value?.sessionId ?? '';
        if (sessionId.isNotEmpty) {
          Get.offNamed(AppRoutes.examWaiting, arguments: sessionId);
        }
      }
    });
  }

  Future<void> _captureImage({required String questionId}) async {
    if (controller.imagesForQuestion(questionId).any(
      (img) =>
          img.uploadStatus == ImageUploadStatus.uploaded ||
          img.uploadStatus == ImageUploadStatus.localOnly,
    )) {
      return;
    }

    final cameraPermission = Get.find<CameraPermissionService>();
    final documentScan = Get.find<DocumentEdgeDetectionService>();
    final watchdog = Get.find<SecurityWatchdogService>();
    final checkConnectivity = Get.find<CheckConnectivityUseCase>();

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

      final connectivityResult = await checkConnectivity();
      final isOnline = connectivityResult.dataOrNull?.isOnline ?? false;

      if (!isOnline) {
        await controller.saveDraftForQuestion(questionId);
        controller.infoMessage.value = AppStrings.writtenExamImageSavedOffline;
        WrittenExamImageAddedToast.show();
        return;
      }

      final uploaded = await controller.uploadStagedImage(
        questionId: questionId,
      );
      if (!mounted) return;

      if (uploaded) {
        WrittenExamImageAddedToast.show();
      } else {
        await controller.saveDraftForQuestion(questionId);
        if (!isOnline) {
          controller.infoMessage.value = AppStrings.writtenExamImageSavedOffline;
        }
      }
    } finally {
      watchdog.setCameraCaptureActive(false);
    }
  }

  bool _isNavigatingToReview = false;

  Future<void> _goToSubmitReview() async {
    if (_isNavigatingToReview) return;
    _isNavigatingToReview = true;
    try {
      await controller.flushPendingAnswer();
      await Get.offNamed(AppRoutes.examSubmitReview);
    } finally {
      _isNavigatingToReview = false;
    }
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
              return const SizedBox.shrink();
            }

            final question = controller.currentQuestion;
            final questionImages = question != null
                ? controller.imagesForQuestion(question.id)
                : <WrittenAnswerImage>[];
            final hasStagedImage = questionImages.any(
              (img) =>
                  img.uploadStatus == ImageUploadStatus.uploaded ||
                  img.uploadStatus == ImageUploadStatus.localOnly,
            );

            return Stack(
              children: [
                Column(
                  children: [
                    Obx(() {
                      final question = controller.currentQuestion;
                      final isLast = controller.isLastQuestion;
                      final isSaving = controller.submissionStatus.value ==
                          SubmissionStatus.saving;
                      final isBusy = isSaving || controller.isUploading.value;
                      final canFinishLast =
                          !isLast || sessionController.canSubmitExam.value;

                      return WrittenExamHeader(
                        questionIndex: question?.index ?? 0,
                        questionTotal: question?.total ?? 0,
                        formattedTimer:
                            sessionController.timer.value?.formatted ?? '--:--',
                        isSkipEnabled: !isBusy && canFinishLast,
                        onSkip: () {
                          if (isLast) {
                            _goToSubmitReview();
                          } else {
                            controller.skipCurrentQuestion();
                          }
                        },
                      );
                    }),
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
                                    isLocked: hasStagedImage,
                                    onAddImage: () => _captureImage(
                                      questionId: question.id,
                                    ),
                                    onReplace: (_) {},
                                    onDelete: (_) {},
                                  ),
                                  if (controller.infoMessage.value != null) ...[
                                    SizedBox(height: 12.h),
                                    Text(
                                      controller.infoMessage.value!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
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
                    Obx(() {
                      final isLast = controller.isLastQuestion;
                      final isSaving = controller.submissionStatus.value ==
                          SubmissionStatus.saving;
                      final isBusy = isSaving || controller.isUploading.value;
                      final canFinishLast =
                          !isLast || sessionController.canSubmitExam.value;
                      final hasStagedImage = controller.currentQuestionHasStagedImage;

                      return ExamQuestionNavigationBar(
                        canGoBack: false,
                        onPrevious: null,
                        primaryLabel: isLast
                            ? AppStrings.examSubmitReviewReviewAction
                            : AppStrings.nextQuestion,
                        isPrimaryLoading: isSaving,
                        isPrimaryEnabled: isLast
                            ? canFinishLast && !isBusy
                            : hasStagedImage && !isBusy,
                        onPrimary: () async {
                          if (isLast) {
                            await _goToSubmitReview();
                          } else {
                            await controller.goToNext();
                          }
                        },
                      );
                    }),
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
