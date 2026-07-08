import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_png_asset.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../controllers/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.w),
              child: StaggeredEntrance(
                children: [
                  const Center(
                    child: AppLogoView(width: 120, height: 120),
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                  Text(
                    AppStrings.appName,
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  Text(
                    AppStrings.signInSubtitle,
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  _LoginForm(controller: controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller.examineeIdController,
            decoration: const InputDecoration(
              labelText: AppStrings.examineeId,
              border: OutlineInputBorder(),
            ),
            validator: controller.validateExamineeId,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: AppSpacing.md.h),
          TextFormField(
            controller: controller.passwordController,
            decoration: const InputDecoration(
              labelText: AppStrings.password,
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: controller.validatePassword,
            onFieldSubmitted: (_) => controller.login(),
          ),
          SizedBox(height: AppSpacing.md.h),
          Obx(() {
            final error = controller.errorMessage.value;
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md.h),
              child: Text(
                error,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
              ),
            );
          }),
          Obx(() {
            final loading = controller.isLoading.value;
            return AppPrimaryButton(
              label: AppStrings.signIn,
              isLoading: loading,
              onPressed: loading ? null : controller.login,
            );
          }),
        ],
      ),
    );
  }
}
