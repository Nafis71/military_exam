import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../../../security_gate/domain/usecases/start_security_watchdog_usecase.dart';
import '../controllers/mcq_exam_controller.dart';
import '../widgets/mcq_exam_header.dart';
import '../widgets/mcq_question_body.dart';

class McqExamPage extends StatefulWidget {
  const McqExamPage({super.key});

  @override
  State<McqExamPage> createState() => _McqExamPageState();
}

class _McqExamPageState extends State<McqExamPage> {
  late final McqExamController controller;
  late final ExamSessionController sessionController;
  late final String sessionId;

  @override
  void initState() {
    super.initState();
    controller = Get.find<McqExamController>();
    sessionController = Get.find<ExamSessionController>();
    sessionId = Get.arguments as String? ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (sessionController.examSession.value == null && sessionId.isNotEmpty) {
        await sessionController.startSession(sessionId);
      }
      if (sessionController.currentExam.value == null) {
        await sessionController.loadCurrentExam();
      }
      final examSessionId =
          sessionController.examSession.value?.sessionId ?? sessionId;
      if (examSessionId.isNotEmpty) {
        await controller.loadQuestions(examSessionId);
      }
    });
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

            return Column(
              children: [
                Obx(() {
                  final timer = sessionController.timer.value;
                  final question = controller.currentQuestion;
                  return McqExamHeader(
                    questionIndex: question?.index ?? 0,
                    questionTotal: question?.total ?? 0,
                    formattedTimer: timer?.formatted ?? '--:--',
                  );
                }),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final question = controller.currentQuestion;
                    if (question == null) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md.w,
                          ),
                          child: Text(
                            controller.errorMessage.value ??
                                AppStrings.noQuestionsAvailable,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      );
                    }

                    return McqQuestionBody(
                      question: question,
                      selectedOptionId: controller.selectedOptionId.value,
                      onSelectOption: controller.selectOption,
                    );
                  }),
                ),
                _McqNavigationBar(
                  controller: controller,
                  canSubmit: sessionController.canSubmitExam.value,
                  onFinished: _onMcqFinished,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _onMcqFinished() async {
    await controller.submitCurrentAnswer(advance: false);
    final nextRoute =
        sessionController.completePhaseAndGetNextRoute(ExamPhase.mcq);
    final watchdog = Get.find<StartSecurityWatchdogUseCase>();
    await watchdog(
      policy: SecurityPolicy(
        requireAirplaneMode: true,
        monitoredPhases: [
          ExamPhase.mcq,
          ExamPhase.fillBlank,
          ExamPhase.written,
        ],
      ),
      phase: sessionController.currentPhase.value,
      sessionId: sessionController.examSession.value?.sessionId,
    );
    if (nextRoute == AppRoutes.finishExam) {
      final examName = sessionController.currentExam.value?.examName ??
          AppStrings.finishExamDefaultName;
      final success = await sessionController.finalizeExamAndClearLocal();
      if (!success) return;
      Get.offAllNamed(
        AppRoutes.finishExam,
        arguments: <String, dynamic>{
          'examName': examName,
          'submittedAt':
              sessionController.submissionReceipt.value?.submittedAt ??
                  DateTime.now(),
        },
      );
      return;
    }
    Get.offNamed(nextRoute);
  }
}

class _McqNavigationBar extends StatelessWidget {
  const _McqNavigationBar({
    required this.controller,
    required this.canSubmit,
    required this.onFinished,
  });

  final McqExamController controller;
  final bool canSubmit;
  final VoidCallback onFinished;

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
        final submitting = controller.isSubmitting.value;
        final hasSelection = controller.selectedOptionId.value != null;
        final isLast = controller.isLastQuestion;
        final canGoBack = controller.currentIndex.value > 0;
        return Row(
          children: [
            if (canGoBack)
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting ? null : controller.goToPrevious,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.c176B4D,
                    side: const BorderSide(color: AppColors.cD9E5DE),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Text(
                    AppStrings.previousQuestion,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.c176B4D,
                        ),
                  ),
                ),
              ),
            if (canGoBack) SizedBox(width: 12.w),
            Expanded(
              child: AppPrimaryButton(
                label: isLast ? AppStrings.finishMcq : AppStrings.nextQuestion,
                isLoading: submitting,
                onPressed: !hasSelection || submitting || (isLast && !canSubmit)
                    ? null
                    : () async {
                        if (isLast) {
                          onFinished();
                        } else {
                          await controller.submitCurrentAnswer();
                        }
                      },
                boxShadow: hasSelection && !submitting
                    ? [
                        BoxShadow(
                          color: AppColors.c89D5B2.withValues(alpha: 0.4),
                          blurRadius: 28,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        );
      }),
    );
  }
}
