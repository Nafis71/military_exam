import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../security_gate/domain/usecases/start_security_watchdog_usecase.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../controllers/mcq_exam_controller.dart';
import '../widgets/mcq_card.dart';

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
        appBar: AppAppBar(
          title: AppStrings.multipleChoice,
          automaticallyImplyLeading: false,
          actions: [
            Obx(() {
              final timer = sessionController.timer.value;
              if (timer == null) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(right: AppSpacing.md.w),
                child: Center(
                  child: Text(
                    timer.formatted,
                    style: AppTypography.timer.copyWith(
                      color: AppColors.cFFFFFF,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final question = controller.currentQuestion;
          if (question == null) {
            return Center(
              child: Text(
                controller.errorMessage.value ?? AppStrings.noQuestionsAvailable,
                style: AppTypography.bodyMedium,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.lg.w),
                  child: McqCard(
                    question: question,
                    selectedOptionId: controller.selectedOptionId.value,
                    onOptionSelected: controller.selectOption,
                  ),
                ),
              ),
              _McqNavigationBar(
                controller: controller,
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
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Obx(() {
        final submitting = controller.isSubmitting.value;
        final hasSelection = controller.selectedOptionId.value != null;
        return AppPrimaryButton(
          label: controller.isLastQuestion
              ? AppStrings.finishMcq
              : AppStrings.next,
          isLoading: submitting,
          onPressed: !hasSelection || submitting
              ? null
              : () async {
                  if (controller.isLastQuestion) {
                    onFinished();
                  } else {
                    await controller.submitCurrentAnswer();
                  }
                },
        );
      }),
    );
  }
}
