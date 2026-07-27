import '../../shared/domain/enums/exam_run_mode.dart';

/// Tracks whether the current exam flow is a real exam or onboarding demo.
class ExamRunContext {
  ExamRunMode mode = ExamRunMode.real;

  bool get isOnboardingDemo => mode == ExamRunMode.onboardingDemo;

  bool get skipSecurityGates => isOnboardingDemo;

  void setReal() => mode = ExamRunMode.real;

  void setOnboardingDemo() => mode = ExamRunMode.onboardingDemo;

  void reset() => mode = ExamRunMode.real;
}
