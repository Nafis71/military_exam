import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'exam_procedure_timeline_step.dart';

class ExamProcedureTimeline extends StatelessWidget {
  const ExamProcedureTimeline({super.key});

  static final _steps = [
    (
      Icons.meeting_room_outlined,
      AppStrings.procedureStep1Title,
      AppStrings.procedureStep1Description,
    ),
    (
      Icons.qr_code_scanner,
      AppStrings.procedureStep2Title,
      AppStrings.procedureStep2Description,
    ),
    (
      Icons.security,
      AppStrings.procedureStep3Title,
      AppStrings.procedureStep3Description,
    ),
    (
      Icons.vpn_key_outlined,
      AppStrings.procedureStep4Title,
      AppStrings.procedureStep4Description,
    ),
    (
      Icons.keyboard_outlined,
      AppStrings.procedureStep5Title,
      AppStrings.procedureStep5Description,
    ),
    (
      Icons.verified_user_outlined,
      AppStrings.procedureStep6Title,
      AppStrings.procedureStep6Description,
    ),
    (
      Icons.play_circle_outline,
      AppStrings.procedureStep7Title,
      AppStrings.procedureStep7Description,
    ),
    (
      Icons.check_circle_outline,
      AppStrings.procedureStep8Title,
      AppStrings.procedureStep8Description,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          ExamProcedureTimelineStep(
            icon: _steps[i].$1,
            title: _steps[i].$2,
            description: _steps[i].$3,
            isLast: i == _steps.length - 1,
          ),
      ],
    );
  }
}
