import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../finish_exam/presentation/widgets/finish_exam_summary_row.dart';
import '../../domain/entities/exam_submit_summary.dart';
import '../../domain/utils/exam_duration_utils.dart';

class ExamSubmitSummaryCard extends StatelessWidget {
  const ExamSubmitSummaryCard({
    super.key,
    required this.summary,
  });

  final ExamSubmitSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 360.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.cFFFFFF,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.c0F3D2E.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FinishExamSummaryRow(
            label: AppStrings.finishExamNameLabel,
            value: summary.examName,
          ),
          FinishExamSummaryRow(
            label: AppStrings.examSubmitReviewBatchLabel,
            value: summary.batchName,
          ),
          FinishExamSummaryRow(
            label: AppStrings.examSubmitReviewTotalDurationLabel,
            value: ExamDurationUtils.formatMinutes(summary.totalDurationMinutes),
          ),
          FinishExamSummaryRow(
            label: AppStrings.examSubmitReviewElapsedDurationLabel,
            value: ExamDurationUtils.formatElapsedDuration(summary.elapsedSeconds),
          ),
          FinishExamSummaryRow(
            label: AppStrings.examSubmitReviewTotalQuestionsLabel,
            value: '${summary.totalQuestions}',
          ),
          FinishExamSummaryRow(
            label: AppStrings.examSubmitReviewAnsweredQuestionsLabel,
            value: '${summary.answeredQuestions}',
            showBottomBorder: false,
          ),
        ],
      ),
    );
  }
}
