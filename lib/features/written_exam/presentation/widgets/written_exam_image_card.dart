import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

class WrittenExamImageCard extends StatelessWidget {
  const WrittenExamImageCard({
    super.key,
    required this.image,
    required this.pageNumber,
    required this.onReplace,
    required this.onDelete,
  });

  final WrittenAnswerImage image;
  final int pageNumber;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.c0F3D2E.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 240.h,
            width: double.infinity,
            child: Stack(
              children: [
                ColoredBox(
                  color: AppColors.cF0F4F2,
                  child: Center(
                    child: Image.file(
                      File(image.localPath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported_outlined,
                        size: 48.sp,
                        color: AppColors.c66736C,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12.w,
                  top: 12.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.c176B4D,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${AppStrings.writtenExamPagePrefix} ${toBengaliDigits(pageNumber)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cFFFFFF,
                            height: 18 / 12,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 13.h, 16.w, 12.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.cD9E5DE)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _WrittenExamActionButton(
                    label: AppStrings.replace,
                    icon: '↻',
                    backgroundColor: AppColors.cEAF4EF,
                    borderColor: AppColors.cD9E5DE,
                    foregroundColor: AppColors.c176B4D,
                    onTap: onReplace,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _WrittenExamActionButton(
                    label: AppStrings.delete,
                    icon: '✕',
                    backgroundColor: AppColors.cFEF2F2,
                    borderColor: AppColors.cF5C6CC,
                    foregroundColor: AppColors.cC43D4D,
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WrittenExamActionButton extends StatelessWidget {
  const _WrittenExamActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final String icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 11.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: foregroundColor,
                      height: 24 / 16,
                    ),
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: foregroundColor,
                      height: 19.5 / 13,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
