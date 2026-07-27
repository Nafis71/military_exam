import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/widgets/login_text_field.dart';
import '../controllers/candidate_login_controller.dart';

class CandidateLoginForm extends StatelessWidget {
  const CandidateLoginForm({super.key, required this.controller});

  final CandidateLoginController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginTextField(
            label: AppStrings.candidateId,
            hint: AppStrings.candidateIdHint,
            controller: controller.candidateIdController,
            validator: controller.validateCandidateId,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => controller.continueLogin(),
          ),
          SizedBox(height: 20.h),
          LoginTextField(
            label: AppStrings.deviceId,
            hint: AppStrings.deviceId,
            controller: controller.deviceIdController,
            readOnly: true,
          ),
          SizedBox(height: 34.h),
          Obx(() {
            final loading = controller.isLoading.value;
            return SizedBox(
              height: 48.h,
              child: FilledButton(
                onPressed: loading ? null : controller.continueLogin,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.c0A5943,
                  disabledBackgroundColor:
                      AppColors.c0A5943.withValues(alpha: 0.5),
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
                        AppStrings.continueLabel,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.cFFFFFF,
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
