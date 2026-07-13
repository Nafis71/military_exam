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
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../controllers/written_exam_controller.dart';
import '../widgets/written_exam_header.dart';
import '../widgets/written_exam_image_added_toast.dart';
import '../widgets/written_exam_info_banner.dart';
import '../widgets/written_exam_question_card.dart';
import '../widgets/written_exam_submit_bar.dart';

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

  Future<void> _captureImage({
    required String questionId,
    String? replaceLocalId,
  }) async {
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

      if (scannedPath != null) {
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/written_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(scannedPath).copy(filePath);
        final previousCount = controller.images.length;
        if (replaceLocalId != null) {
          await controller.replaceImage(replaceLocalId, filePath);
        } else {
          await controller.addImage(questionId, filePath);
        }
        if (mounted &&
            controller.errorMessage.value == null &&
            controller.images.isNotEmpty &&
            (replaceLocalId != null || controller.images.length > previousCount)) {
          WrittenExamImageAddedToast.show();
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
      final submittedAt =
          sessionController.submissionReceipt.value?.submittedAt ??
              controller.submissionReceipt.value?.submittedAt ??
              DateTime.now();
      Get.offAllNamed(
        AppRoutes.finishExam,
        arguments: <String, dynamic>{
          'examName': AppStrings.finishExamDefaultName,
          'submittedAt': submittedAt,
        },
      );
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
            final hasAnyImages = controller.hasAnyImages;

            return Column(
              children: [
                const WrittenExamHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      20.h,
                      20.w,
                      AppSpacing.lg.h,
                    ),
                    child: Column(
                      children: [
                        if (!hasAnyImages) ...[
                          const WrittenExamInfoBanner(),
                          SizedBox(height: 16.h),
                        ],
                        ...controller.questions.map(
                          (question) {
                            final questionImages =
                                controller.imagesForQuestion(question.id);
                            return Padding(
                              padding: EdgeInsets.only(bottom: 20.h),
                              child: WrittenExamQuestionCard(
                                question: question,
                                images: questionImages,
                                onAddImage: () => _captureImage(
                                  questionId: question.id,
                                ),
                                onReplace: (localId) => _captureImage(
                                  questionId: question.id,
                                  replaceLocalId: localId,
                                ),
                                onDelete: (localId) =>
                                    controller.deleteImage(localId),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                WrittenExamSubmitBar(
                  onSubmit: _submitWritten,
                  isLoading: controller.submissionStatus.value ==
                      SubmissionStatus.saving,
                  canSubmit: controller.canSubmit,
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
