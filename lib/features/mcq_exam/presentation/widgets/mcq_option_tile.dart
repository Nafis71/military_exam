import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

class McqOptionTile extends StatelessWidget {
  const McqOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final McqOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md.w,
            vertical: AppSpacing.md.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundColor:
                    isSelected ? AppColors.primary : AppColors.border,
                child: Text(
                  option.id.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected ? AppColors.surface : AppColors.textPrimary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Text(option.label, style: AppTypography.bodyLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
