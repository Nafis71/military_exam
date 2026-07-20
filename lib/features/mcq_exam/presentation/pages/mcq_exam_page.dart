import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../core/widgets/exam_question_navigation_bar.dart';
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
      if (!sessionController.canAccessQuestions.value) {
        Get.offNamed(AppRoutes.examWaiting, arguments: sessionId);
        return;
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
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                Obx(() {
                  final timer = sessionController.timer.value;
                  final question = controller.currentQuestion;
                  final submitting = controller.isSubmitting.value;
                  final isLast = controller.isLastQuestion;
                  final canFinishLast =
                      !isLast || sessionController.canSubmitExam.value;

                  return McqExamHeader(
                    questionIndex: question?.index ?? 0,
                    questionTotal: question?.total ?? 0,
                    formattedTimer: timer?.formatted ?? '--:--',
                    isSkipEnabled: !submitting && canFinishLast,
                    onSkip: () {
                      if (isLast) {
                        _onMcqFinished();
                      } else {
                        controller.skipCurrentQuestion();
                      }
                    },
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
                Obx(() {
                  final submitting = controller.isSubmitting.value;
                  final hasSelection = controller.selectedOptionId.value != null;
                  final isLast = controller.isLastQuestion;
                  final canGoBack = controller.currentIndex.value > 0;
                  final canFinishLast =
                      !isLast || sessionController.canSubmitExam.value;

                  return ExamQuestionNavigationBar(
                    canGoBack: canGoBack,
                    onPrevious: submitting ? null : controller.goToPrevious,
                    primaryLabel: isLast
                        ? AppStrings.finishMcq
                        : AppStrings.nextQuestion,
                    isPrimaryLoading: submitting,
                    isPrimaryEnabled:
                        hasSelection && !submitting && canFinishLast,
                    primaryBoxShadow: hasSelection && !submitting
                        ? [
                            BoxShadow(
                              color: AppColors.c89D5B2.withValues(alpha: 0.4),
                              blurRadius: 28,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                    onPrimary: () async {
                      if (isLast) {
                        _onMcqFinished();
                      } else {
                        await controller.submitCurrentAnswer();
                      }
                    },
                  );
                }),
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
