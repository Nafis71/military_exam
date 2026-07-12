import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/png_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_png_asset.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 19.h, bottom: 62.h),
      child: Column(
        children: [
          AppPngAsset(
            assetPath: PngAsset.appLogo,
            width: 108.w,
            height: 108.w,
          ),
          SizedBox(height: 9.h),
          Text(
            AppStrings.appName,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.cFFFFFF,
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            AppStrings.appSubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.cFFFFFF.withValues(alpha: 0.75),
              fontSize: 13.sp,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
