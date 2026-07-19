import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_status_icon_card.dart';
import '../../domain/finish_submission_type.dart';
import 'finish_exam_success_icon.dart';

class FinishExamStatusIcon extends StatelessWidget {
  const FinishExamStatusIcon({
    super.key,
    required this.submissionType,
  });

  final FinishSubmissionType submissionType;

  @override
  Widget build(BuildContext context) {
    if (submissionType == FinishSubmissionType.manual) {
      return const FinishExamSuccessIcon();
    }

    return AppStatusIconCard(
      glowColor: AppColors.cF59E0B.withValues(alpha: 0.35),
      circleColor: AppColors.cF59E0B.withValues(alpha: 0.18),
      child: Icon(
        Icons.schedule_rounded,
        size: 52.w,
        color: AppColors.cF59E0B,
      ),
    );
  }
}
