import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';

class ViolationController extends GetxController {
  final violation = Rxn<SecurityViolation>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SecurityViolation) {
      violation.value = args;
    }
  }

  String get title => AppStrings.examPenalized;

  String get message =>
      violation.value?.type.displayMessage ??
      AppStrings.securityViolationLocked;

  String get publishedMessage => AppStrings.examAnswersPublished;

  bool get isBackgroundViolation {
    final type = violation.value?.type;
    return type == ViolationType.appBackgrounded ||
        type == ViolationType.appMinimized;
  }
}
