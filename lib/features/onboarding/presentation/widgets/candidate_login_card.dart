import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'candidate_login_form.dart';
import '../controllers/candidate_login_controller.dart';

class CandidateLoginCard extends StatelessWidget {
  const CandidateLoginCard({super.key, required this.controller});

  final CandidateLoginController controller;

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
          padding: EdgeInsets.fromLTRB(24.w, 29.h, 24.w, 58.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.candidateIdDescription,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.c66736C,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 35.h),
              CandidateLoginForm(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}
