import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

const _bengaliOptionLetters = ['ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ', 'ছ', 'জ', 'ঝ', 'ঞ'];

class McqOptionTile extends StatelessWidget {
  const McqOptionTile({
    super.key,
    required this.option,
    required this.optionIndex,
    required this.isSelected,
    required this.onTap,
  });

  final McqOption option;
  final int optionIndex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final letter = optionIndex < _bengaliOptionLetters.length
        ? _bengaliOptionLetters[optionIndex]
        : '${optionIndex + 1}';

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 60.h),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cEAF4EF : AppColors.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? AppColors.c176B4D : AppColors.cD9E5DE,
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.c176B4D : AppColors.surface,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: isSelected ? AppColors.c176B4D : AppColors.cD9E5DE,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.cFFFFFF : AppColors.c66736C,
                    ),
                    child: Text(letter),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 15.sp,
                    color: isSelected ? AppColors.c0F3D2E : AppColors.c17231D,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
                  child: Text(option.label, softWrap: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
