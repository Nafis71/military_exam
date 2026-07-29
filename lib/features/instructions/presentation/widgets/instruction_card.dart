import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_asset.dart';

class InstructionCard extends StatelessWidget {
  const InstructionCard({
    super.key,
    this.icon,
    this.svgAssetPath,
    required this.title,
    required this.description,
    this.useLightText = false,
  }) : assert(icon != null || svgAssetPath != null);

  final IconData? icon;
  final String? svgAssetPath;
  final String title;
  final String description;
  final bool useLightText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              color: AppColors.cFFFFFF,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.c89D5B2.withValues(alpha: 0.7),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: AppColors.c89D5B2.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: svgAssetPath != null
                    ? AppSvgAsset(
                        assetPath: svgAssetPath!,
                        width: 52.w,
                        height: 52.w,
                      )
                    : Icon(icon!, size: 52.sp, color: AppColors.c0A5943),
              ),
            ),
          ),
          SizedBox(height: 44.h),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: useLightText ? AppColors.cFFFFFF : AppColors.c094C3C,
                  height: 28 / 20,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: useLightText ? AppColors.cFFFFFF : AppColors.c474E5A,
                  height: 22 / 14,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
