import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/domain/entities/device_details.dart';

class DashboardDeviceInfoSection extends StatelessWidget {
  const DashboardDeviceInfoSection({
    super.key,
    required this.brandName,
    required this.modelNumber,
    required this.osVersion,
    this.isAvailable = true,
  });

  final String brandName;
  final String modelNumber;
  final String osVersion;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.deviceInfoTitle,
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.cFFFFFF.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        if (!isAvailable)
          Text(
            AppStrings.deviceInfoUnavailable,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.cFFFFFF.withValues(alpha: 0.8),
            ),
          )
        else ...[
          _DeviceInfoRow(
            label: AppStrings.deviceBrandName,
            value: brandName,
          ),
          SizedBox(height: AppSpacing.xs.h),
          _DeviceInfoRow(
            label: AppStrings.deviceModelNumber,
            value: modelNumber,
          ),
          SizedBox(height: AppSpacing.xs.h),
          _DeviceInfoRow(
            label: AppStrings.deviceOsVersion,
            value: osVersion,
          ),
        ],
      ],
    );
  }
}

class _DeviceInfoRow extends StatelessWidget {
  const _DeviceInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayValue =
        value.trim().isEmpty ? DeviceDetails.unavailableValue : value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.cFFFFFF.withValues(alpha: 0.8),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            displayValue,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.cFFFFFF,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
