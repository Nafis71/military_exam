import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../core/widgets/exam_question_navigation_bar.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../../../security_gate/domain/usecases/start_security_watchdog_usecase.dart';
import '../controllers/fill_blank_exam_controller.dart';
import '../widgets/fill_blank_exam_header.dart';
import '../widgets/fill_blank_question_body.dart';

class FillBlankExamPage extends StatefulWidget {
  const FillBlankExamPage({super.key});

  @override
  State<FillBlankExamPage> createState() => _FillBlankExamPageState();
}

class _FillBlankExamPageState extends State<FillBlankExamPage> {
  late final FillBlankExamController controller;
  late final ExamSessionController sessionController;
  late final String sessionId;

  @override
  void initState() {
    super.initState();
    controller = Get.find<FillBlankExamController>();
    sessionController = Get.find<ExamSessionController>();
    sessionId = Get.arguments as String? ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (sessionController.examSession.value == null && sessionId.isNotEmpty) {
        await sessionController.startSession(sessionId);
      }
      final refreshFromApi = !Get.find<ExamRunContext>().isOnboardingDemo;
      await sessionController.loadCurrentExam(refresh: refreshFromApi);
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
                  final saving = controller.isSaving.value;
                  final isLast = controller.isLastQuestion;
                  final canFinishLast =
                      !isLast || sessionController.canSubmitExam.value;

                  return FillBlankExamHeader(
                    questionIndex: question?.index ?? 0,
                    questionTotal: question?.total ?? 0,
                    formattedTimer: timer?.formatted ?? '--:--',
                    isSkipEnabled: !saving && canFinishLast,
                    onSkip: () {
                      if (isLast) {
                        _onFillBlankFinished();
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

                    return FillBlankQuestionBody(
                      question: question,
                      answerText: controller.answerText.value,
                      onAnswerChanged: controller.updateAnswer,
                    );
                  }),
                ),
                Obx(() {
                  final saving = controller.isSaving.value;
                  final isLast = controller.isLastQuestion;
                  final canGoBack = controller.currentIndex.value > 0;
                  final canFinishLast =
                      !isLast || sessionController.canSubmitExam.value;

                  return ExamQuestionNavigationBar(
                    canGoBack: canGoBack,
                    onPrevious: saving ? null : controller.goToPrevious,
                    primaryLabel: isLast
                        ? AppStrings.finishFillBlank
                        : AppStrings.nextQuestion,
                    isPrimaryLoading: saving,
                    isPrimaryEnabled: !saving && canFinishLast,
                    onPrimary: () async {
                      if (isLast) {
                        _onFillBlankFinished();
                      } else {
                        await controller.saveCurrentAnswer();
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

  Future<void> _onFillBlankFinished() async {
    await controller.saveCurrentAnswer(advance: false);
    final nextRoute =
        sessionController.completePhaseAndGetNextRoute(ExamPhase.fillBlank);
    final watchdog = Get.find<StartSecurityWatchdogUseCase>();
    await watchdog(
      policy: const SecurityPolicy(
        requireAirplaneMode: true,
        requireVpnLockdown: true,
        monitoredPhases: [
          ExamPhase.mcq,
          ExamPhase.fillBlank,
          ExamPhase.written,
        ],
      ),
      phase: sessionController.currentPhase.value,
      sessionId: sessionController.examSession.value?.sessionId,
    );
    if (nextRoute == AppRoutes.examSubmitReview) {
      await Get.offNamed(AppRoutes.examSubmitReview);
      return;
    }
    Get.offNamed(nextRoute);
  }
}
