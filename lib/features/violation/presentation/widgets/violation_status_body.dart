import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/svg_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_status_icon_card.dart';
import '../../../../core/widgets/app_svg_asset.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import 'violation_info_card.dart';
import 'violation_message_card.dart';

/// Shared violation layout matching Figma — icon, title, message, info cards.
class ViolationStatusBody extends StatelessWidget {
  const ViolationStatusBody({
    super.key,
    required this.title,
    required this.message,
    required this.alertMessage,
    required this.bullets,
    this.contentKey,
    this.isSubmitting = false,
  });

  final String title;
  final String message;
  final String alertMessage;
  final List<String> bullets;
  final Object? contentKey;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: StaggeredEntrance(
                contentKey: contentKey,
                children: [
                  Center(
                    child: AppStatusIconCard(
                      glowColor: AppColors.cFEE2E2,
                      circleColor: AppColors.cFEE2E2,
                      child: AppSvgAsset(
                        assetPath: SvgAsset.shieldLock,
                        width: 75.w,
                        height: 75.w,
                        semanticsLabel: AppStrings.securityViolation,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cC43D4D,
                      height: 33.6 / 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 34.h),
                  ViolationMessageCard(
                    message: message,
                    alertMessage: alertMessage,
                  ),
                  if (isSubmitting) ...[
                    SizedBox(height: 20.h),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  SizedBox(height: 20.h),
                  ViolationInfoCard(bullets: bullets),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
