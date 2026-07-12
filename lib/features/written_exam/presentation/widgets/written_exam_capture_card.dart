import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/svg_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_asset.dart';
import '../../../../core/widgets/dashed_border.dart';

class WrittenExamCaptureCard extends StatelessWidget {
  const WrittenExamCaptureCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: DashedBorder(
          color: AppColors.cD9E5DE,
          strokeWidth: 2,
          borderRadius: 24.r,
          padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 50.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: AppColors.cEAF4EF,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                alignment: Alignment.center,
                child: AppSvgAsset(
                  assetPath: SvgAsset.writtenExamCamera,
                  width: 40.w,
                  height: 40.w,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                AppStrings.writtenExamCaptureTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.c176B4D,
                      height: 24 / 16,
                    ),
              ),
              SizedBox(height: 6.h),
              Text(
                AppStrings.writtenExamCaptureSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.c66736C,
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
