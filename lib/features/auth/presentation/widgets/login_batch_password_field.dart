import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/login_controller.dart';
import 'login_text_field.dart';

class LoginBatchPasswordField extends StatelessWidget {
  const LoginBatchPasswordField({super.key, required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginTextField(
          label: AppStrings.batchPassword,
          hint: AppStrings.batchPasswordHint,
          controller: controller.batchPasswordController,
          obscureText: true,
          showVisibilityToggle: true,
          validator: Validators.password,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => controller.login(),
        ),
      ],
    );
  }
}
