import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/login_controller.dart';

class LoginGoBackButton extends StatelessWidget {
  const LoginGoBackButton({super.key, required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final loading = controller.isLoading.value;

      return TextButton(
        onPressed: loading ? null : controller.goBack,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.c0A5943,
          disabledForegroundColor: AppColors.c0A5943.withValues(alpha: 0.5),
          padding: EdgeInsets.symmetric(vertical: 12.h),
        ),
        child: Text(
          AppStrings.goBack,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: loading
                ? AppColors.c0A5943.withValues(alpha: 0.5)
                : AppColors.c0A5943,
          ),
        ),
      );
    });
  }
}
