import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../security_gate/domain/usecases/start_security_watchdog_usecase.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
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
          body: Column(
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
                onFinished: _onMcqFinished,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onMcqFinished() async {
    await controller.submitCurrentAnswer(advance: false);
    sessionController.advanceToWrittenPhase();
    final watchdog = Get.find<StartSecurityWatchdogUseCase>();
    await watchdog(
      policy: SecurityPolicy(
        requireAirplaneMode: true,
        monitoredPhases: [ExamPhase.mcq, ExamPhase.written],
      ),
      phase: ExamPhase.written,
      sessionId: sessionController.examSession.value?.sessionId,
    );
    Get.offNamed(AppRoutes.writtenExam);
  }
}

class _McqNavigationBar extends StatelessWidget {
  const _McqNavigationBar({
    required this.controller,
    required this.onFinished,
  });

  final McqExamController controller;
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
        return AppPrimaryButton(
          label: isLast ? AppStrings.finishMcq : AppStrings.nextQuestion,
          isLoading: submitting,
          onPressed: !hasSelection || submitting
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
        );
      }),
    );
  }
}
