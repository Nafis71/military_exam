import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/login_controller.dart';
import 'login_form.dart';

class LoginCard extends StatelessWidget {
  const LoginCard({super.key, required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        margin: REdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.c0F3D2E.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          // top=29 matches Figma description text top position inside card
          // horizontal=24 matches Figma left/right insets (24px each)
          // bottom=58 matches Figma gap from button bottom to card bottom
          padding: EdgeInsets.fromLTRB(24.w, 29.h, 24.w, 58.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.loginDescription,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.c66736C,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              // gap from description bottom to first input group top = 35px (Figma: 109 - 29 - ~45)
              SizedBox(height: 35.h),
              LoginForm(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}
