import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/exam_question_header.dart';

class FillBlankExamHeader extends StatelessWidget {
  const FillBlankExamHeader({
    super.key,
    required this.questionIndex,
    required this.questionTotal,
    required this.formattedTimer,
    this.onSkip,
    this.isSkipEnabled = false,
  });

  final int questionIndex;
  final int questionTotal;
  final String formattedTimer;
  final VoidCallback? onSkip;
  final bool isSkipEnabled;

  @override
  Widget build(BuildContext context) {
    return ExamQuestionHeader(
      phaseLabel: AppStrings.fillInBlank,
      questionIndex: questionIndex,
      questionTotal: questionTotal,
      formattedTimer: formattedTimer,
      onSkip: onSkip,
      isSkipEnabled: isSkipEnabled,
    );
  }
}
