import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'dashboard_device_info_section.dart';
import 'dashboard_unbind_button.dart';

class DashboardDeviceBindingSection extends StatefulWidget {
  const DashboardDeviceBindingSection({
    super.key,
    required this.brandName,
    required this.modelNumber,
    required this.osVersion,
    this.isDeviceInfoAvailable = true,
    this.isUnbinding = false,
    this.onUnbind,
  });

  final String brandName;
  final String modelNumber;
  final String osVersion;
  final bool isDeviceInfoAvailable;
  final bool isUnbinding;
  final VoidCallback? onUnbind;

  @override
  State<DashboardDeviceBindingSection> createState() =>
      _DashboardDeviceBindingSectionState();
}

class _DashboardDeviceBindingSectionState
    extends State<DashboardDeviceBindingSection> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final expandLabel = _isExpanded
        ? AppStrings.deviceBindingHideDetails
        : AppStrings.deviceBindingShowDetails;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: expandLabel,
            expanded: _isExpanded,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(6.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.deviceBindingNote,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.c000000,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs.h),
                          Text(
                            AppStrings.deviceBindingResetNote,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.c000000,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm.w),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.c000000,
                      size: 22.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppSpacing.md.h),
                      DashboardDeviceInfoSection(
                        brandName: widget.brandName,
                        modelNumber: widget.modelNumber,
                        osVersion: widget.osVersion,
                        isAvailable: widget.isDeviceInfoAvailable,
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: DashboardUnbindButton(
                          onPressed: widget.onUnbind,
                          isLoading: widget.isUnbinding,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
