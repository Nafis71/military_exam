import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/png_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_png_asset.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../controllers/get_started_controller.dart';

class GetStartedPage extends GetView<GetStartedController> {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
          child: Column(
            children: [
              SizedBox(height: 80.h),
              AppPngAsset(
                assetPath: PngAsset.appLogo,
                width: 160.w,
                height: 160.w,
              ),
              SizedBox(height: 40.h),
              Text(
                AppStrings.getStartedTitle,
                style: textTheme.displayLarge?.copyWith(
                  color: AppColors.c0F3D2E,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                AppStrings.getStartedSubtitle,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.c66736C,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                AppStrings.getStartedDescription,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.c66736C,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppPrimaryButton(
                label: AppStrings.getStarted,
                onPressed: controller.onGetStarted,
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
