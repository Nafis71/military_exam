import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class McqExamHeader extends StatelessWidget {
  const McqExamHeader({
    super.key,
    required this.questionIndex,
    required this.questionTotal,
    required this.formattedTimer,
  });

  final int questionIndex;
  final int questionTotal;
  final String formattedTimer;

  @override
  Widget build(BuildContext context) {
    final progress = questionTotal > 0 ? questionIndex / questionTotal : 0.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.35, -1.0),
          end: Alignment(0.35, 1.0),
          colors: [AppColors.c0F3D2E, AppColors.c176B4D],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            (20.w).clamp(12.0, 20.0),
            (12.h).clamp(8.0, 12.0),
            (20.w).clamp(12.0, 20.0),
            (12.h).clamp(8.0, 12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${AppStrings.questionOf} $questionIndex${AppStrings.of}$questionTotal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 13.sp,
                            color: AppColors.cFFFFFF.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(width: (8.w).clamp(6.0, 8.0)),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.48,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: _TimerPill(formattedTimer: formattedTimer),
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: (10.h).clamp(6.0, 10.0)),
              _ProgressBar(progress: progress),
              SizedBox(height: (10.h).clamp(6.0, 10.0)),
              Center(
                child: Text(
                  AppStrings.multipleChoice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cFFFFFF.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.formattedTimer});

  final String formattedTimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.cFFFFFF.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, color: AppColors.cFFFFFF, size: 20.sp),
          SizedBox(width: 6.w),
          Text(
            formattedTimer,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.bodyLarge.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.cFFFFFF,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        height: 4.h,
        color: AppColors.cFFFFFF.withValues(alpha: 0.2),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.c4ADE80,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
      ),
    );
  }
}
