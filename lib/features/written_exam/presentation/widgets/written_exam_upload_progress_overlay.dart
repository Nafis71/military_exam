import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class WrittenExamUploadProgressOverlay extends StatelessWidget {
  const WrittenExamUploadProgressOverlay({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).round();

    return ColoredBox(
      color: AppColors.c0F3D2E.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          width: 260.w,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.c0F3D2E.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.writtenExamUploading,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.c17231D,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: 96.w,
                height: 96.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96.w,
                      height: 96.w,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        strokeWidth: 6,
                        backgroundColor: AppColors.cEAF4EF,
                        color: AppColors.c176B4D,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.c176B4D,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
