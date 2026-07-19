import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';

class ViolationController extends GetxController {
  final violation = Rxn<SecurityViolation>();
  final answersSubmitted = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SecurityViolation) {
      violation.value = args;
      return;
    }
    if (args is Map) {
      final violationArg = args['violation'];
      if (violationArg is SecurityViolation) {
        violation.value = violationArg;
      }
      final submitted = args['answersSubmitted'];
      if (submitted is bool) {
        answersSubmitted.value = submitted;
      }
    }
  }

  String get title => AppStrings.examPenalized;

  String get message =>
      violation.value?.type.displayMessage ??
      AppStrings.securityViolationLocked;

  String get alertMessage => answersSubmitted.value
      ? AppStrings.examAnswersPublished
      : AppStrings.examCancelledAndRecorded;

  List<String> get bullets => [
        isBackgroundViolation
            ? AppStrings.violationRuleBackgroundForbidden
            : AppStrings.violationRuleGeneric,
        AppStrings.violationReportedToAuthority,
      ];

  bool get isBackgroundViolation {
    final type = violation.value?.type;
    return type == ViolationType.appBackgrounded ||
        type == ViolationType.appMinimized;
  }
}
