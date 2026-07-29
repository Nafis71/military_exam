import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/violation_icon.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../../core/widgets/security_status_body.dart';

class SecurityErrorPage extends StatelessWidget {
  const SecurityErrorPage({super.key});

  SecurityViolation? get _violation {
    final args = Get.arguments;
    return args is SecurityViolation ? args : null;
  }

  @override
  Widget build(BuildContext context) {
    final violation = _violation;
    final message = violation?.type.displayMessage ??
        AppStrings.securityViolationDuringExam;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: SecurityStatusBody(
            contentKey: violation?.type ?? message,
            title: AppStrings.examinationLocked,
            message: message,
            icon: const ViolationIcon(),
            iconColor: AppColors.error,
            footer: violation == null
                ? null
                : Text(
                    'সেশন ${violation.sessionId ?? AppStrings.sessionUnknown}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }
}
