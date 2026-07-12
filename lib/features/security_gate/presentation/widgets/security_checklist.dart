import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class SecurityChecklist extends StatelessWidget {
  const SecurityChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChecklistRow(label: AppStrings.airplaneModeActive),
        SizedBox(height: 12.h),
        _ChecklistRow(label: AppStrings.developerModeInactive),
        SizedBox(height: 12.h),
        _ChecklistRow(label: AppStrings.wifiConnected),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.cEAF4EF,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: AppColors.c1D8A57,
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: Text(
              '✓',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.cFFFFFF,
                    height: 1,
                  ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.c0F3D2E,
                    height: 21 / 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
