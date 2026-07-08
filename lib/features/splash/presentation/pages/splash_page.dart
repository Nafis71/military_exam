import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_png_asset.dart';
import '../controllers/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogoView(width: 180, height: 180),
            SizedBox(height: AppSpacing.lg.h),
            Text(
              AppStrings.appName,
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.black,
              ),
            ),
            SizedBox(height: AppSpacing.xl.h),
            const CircularProgressIndicator(color: AppColors.c1B3A2F),
          ],
        ),
      ),
    );
  }
}
