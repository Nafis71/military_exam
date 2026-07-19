import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/login_controller.dart';
import 'login_district_dropdown.dart';
import 'login_text_field.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key, required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginTextField(
            label: AppStrings.examineeId,
            hint: AppStrings.examineeIdHint,
            controller: controller.examineeIdController,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 20.h),
          LoginDistrictDropdown(controller: controller),
          Obx(() {
            final error = controller.errorMessage.value;
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                error,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            );
          }),
          // gap from field group bottom to button = 34px (Figma: 329 - 212 - 83)
          SizedBox(height: 34.h),
          _SignInButton(onPressed: controller.login),
        ],
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = (Get.find<LoginController>()).isLoading.value;
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.c89D5B2.withValues(alpha: 0.4),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SizedBox(
          height: 48.h,
          width: double.infinity,
          child: FilledButton(
            onPressed: loading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.c0A5943,
              disabledBackgroundColor: AppColors.c0A5943.withValues(alpha: 0.5),
              foregroundColor: AppColors.cFFFFFF,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: loading
                ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.cFFFFFF,
                    ),
                  )
                : Text(
                    AppStrings.signIn,
                    style: TextStyle(
                      fontFamily: 'HindSiliguri',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cFFFFFF,
                      height: 24 / 18,
                    ),
                  ),
          ),
        ),
      );
    });
  }
}
