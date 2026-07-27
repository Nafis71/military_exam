import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/login_controller.dart';
import 'login_text_field.dart';

class LoginBatchPasswordField extends StatelessWidget {
  const LoginBatchPasswordField({super.key, required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginTextField(
          label: AppStrings.batchPassword,
          hint: AppStrings.batchPasswordHint,
          controller: controller.batchPasswordController,
          obscureText: true,
          showVisibilityToggle: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => controller.login(),
        ),
        SizedBox(height: 8.h),
        Text(
          AppStrings.batchPasswordNote,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.c66736C,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
