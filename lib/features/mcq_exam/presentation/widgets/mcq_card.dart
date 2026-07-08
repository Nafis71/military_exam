import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import 'mcq_option_tile.dart';

class McqCard extends StatelessWidget {
  const McqCard({
    super.key,
    required this.question,
    required this.selectedOptionId,
    required this.onOptionSelected,
  });

  final McqQuestion question;
  final String? selectedOptionId;
  final ValueChanged<String> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        child: StaggeredEntrance(
          contentKey: question.id,
          duration: AppConstants.mcqQuestionEntranceDuration,
          children: [
            Text(
              '${AppStrings.questionOf} ${question.index} ${AppStrings.of} ${question.total}',
              style: AppTypography.bodyMedium,
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(question.question, style: AppTypography.titleMedium),
            SizedBox(height: AppSpacing.lg.h),
            ...question.options.map(
              (option) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                child: McqOptionTile(
                  option: option,
                  isSelected: selectedOptionId == option.id,
                  onTap: () => onOptionSelected(option.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
