import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../onboarding/domain/entities/onboarding_candidate.dart';
import 'dashboard_device_binding_section.dart';

class DashboardProfileCard extends StatelessWidget {
  const DashboardProfileCard({
    super.key,
    this.candidate,
    this.isDeviceBound = false,
    this.isUnbinding = false,
    this.deviceBrandName = '—',
    this.deviceModelNumber = '—',
    this.deviceOsVersion = '—',
    this.isDeviceInfoAvailable = false,
    this.onUnbind,
  });

  final OnboardingCandidate? candidate;
  final bool isDeviceBound;
  final bool isUnbinding;
  final String deviceBrandName;
  final String deviceModelNumber;
  final String deviceOsVersion;
  final bool isDeviceInfoAvailable;
  final VoidCallback? onUnbind;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.c0F3D2E.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32.r,
                backgroundColor: AppColors.cD9E5DE,
                child: Icon(Icons.person, color: AppColors.c0A5943, size: 32.sp),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            candidate?.fullName ?? '—',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.c0F3D2E,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isDeviceBound)
                          Semantics(
                            label: AppStrings.deviceBoundAccessibilityLabel,
                            child: Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.primary,
                              size: 22.sp,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${AppStrings.candidateId}: ${candidate?.candidateId ?? '—'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.c66736C,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${AppStrings.phoneNumber}: ${candidate?.phoneNumber ?? '—'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.c66736C,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${AppStrings.emailAddress}: ${candidate?.emailAddress ?? '—'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.c66736C,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isDeviceBound) ...[
            SizedBox(height: AppSpacing.md.h),
            Divider(color: AppColors.cE8EAED, height: 1.h),
            SizedBox(height: AppSpacing.md.h),
            DashboardDeviceBindingSection(
              brandName: deviceBrandName,
              modelNumber: deviceModelNumber,
              osVersion: deviceOsVersion,
              isDeviceInfoAvailable: isDeviceInfoAvailable,
              isUnbinding: isUnbinding,
              onUnbind: onUnbind,
            ),
          ],
        ],
      ),
    );
  }
}
