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
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../controllers/written_exam_controller.dart';
import '../widgets/written_exam_capture_card.dart';
import '../widgets/written_exam_gallery_banned.dart';
import '../widgets/written_exam_header.dart';
import '../widgets/written_exam_image_added_toast.dart';
import '../widgets/written_exam_image_card.dart';
import '../widgets/written_exam_info_banner.dart';
import '../widgets/written_exam_submit_bar.dart';
import 'camera_capture_page.dart';

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
          builder: (_) => CameraCapturePage(camera: camera),
          fullscreenDialog: true,
        ),
      );

      if (captured != null) {
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/written_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(captured.path).copy(filePath);
        final previousCount = controller.images.length;
        if (replaceLocalId != null) {
          await controller.replaceImage(replaceLocalId, filePath);
        } else {
          await controller.addImage(filePath);
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
            final hasImages = controller.images.isNotEmpty;

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
                        if (!hasImages) ...[
                          const WrittenExamInfoBanner(),
                          SizedBox(height: 16.h),
                        ],
                        if (hasImages) ...[
                          ...controller.images.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: WrittenExamImageCard(
                                image: entry.value,
                                pageNumber: entry.key + 1,
                                onReplace: () => _captureImage(
                                  replaceLocalId: entry.value.localId,
                                ),
                                onDelete: () =>
                                    controller.deleteImage(entry.value.localId),
                              ),
                            ),
                          ),
                        ],
                        WrittenExamCaptureCard(onTap: _captureImage),
                        if (!hasImages) ...[
                          SizedBox(height: 16.h),
                          const WrittenExamGalleryBanned(),
                        ],
                      ],
                    ),
                  ),
                ),
                WrittenExamSubmitBar(
                  onSubmit: _submitWritten,
                  isLoading: controller.submissionStatus.value ==
                      SubmissionStatus.saving,
                  canSubmit: hasImages,
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
