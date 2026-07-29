import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'dashboard_device_info_section.dart';
import 'dashboard_showcase_target.dart';
import 'dashboard_unbind_button.dart';

class DashboardDeviceBindingSection extends StatefulWidget {
  const DashboardDeviceBindingSection({
    super.key,
    required this.brandName,
    required this.modelNumber,
    required this.osVersion,
    this.isDeviceInfoAvailable = true,
    this.isUnbinding = false,
    this.isExpanded,
    this.onExpandedChanged,
    this.deviceInfoShowcaseKey,
    this.onUnbind,
  });

  final String brandName;
  final String modelNumber;
  final String osVersion;
  final bool isDeviceInfoAvailable;
  final bool isUnbinding;
  final bool? isExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final GlobalKey? deviceInfoShowcaseKey;
  final VoidCallback? onUnbind;

  @override
  State<DashboardDeviceBindingSection> createState() =>
      _DashboardDeviceBindingSectionState();
}

class _DashboardDeviceBindingSectionState
    extends State<DashboardDeviceBindingSection> {
  bool _internalExpanded = false;

  bool get _isExpanded => widget.isExpanded ?? _internalExpanded;

  void _setExpanded(bool value) {
    if (widget.onExpandedChanged != null) {
      widget.onExpandedChanged!(value);
      return;
    }
    setState(() => _internalExpanded = value);
  }

  void _toggleExpanded() {
    _setExpanded(!_isExpanded);
  }

  String get _deviceBindingResetNote {
    if (!kIsWeb && Platform.isIOS) {
      return AppStrings.deviceBindingResetNoteIos;
    }
    return AppStrings.deviceBindingResetNote;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final expandLabel = _isExpanded
        ? AppStrings.deviceBindingHideDetails
        : AppStrings.deviceBindingShowDetails;

    final deviceInfoSection = DashboardDeviceInfoSection(
      brandName: widget.brandName,
      modelNumber: widget.modelNumber,
      osVersion: widget.osVersion,
      isAvailable: widget.isDeviceInfoAvailable,
    );

    final showcasedDeviceInfo = widget.deviceInfoShowcaseKey != null
        ? DashboardShowcaseTarget(
            showcaseKey: widget.deviceInfoShowcaseKey!,
            title: AppStrings.dashboardTutorialDeviceInfoTitle,
            description: AppStrings.dashboardTutorialDeviceInfoDescription,
            targetBorderRadius: BorderRadius.circular(8.r),
            child: deviceInfoSection,
          )
        : deviceInfoSection;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        gradient: AppColors.brandHeaderGradient,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.c89D5B2.withValues(alpha: 0.4),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
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
                              color: AppColors.cFFFFFF,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs.h),
                          Text(
                            _deviceBindingResetNote,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.cFFFFFF.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm.w),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.cFFFFFF,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isExpanded) ...[
                  SizedBox(height: AppSpacing.md.h),
                  showcasedDeviceInfo,
                  SizedBox(height: AppSpacing.md.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: DashboardUnbindButton(
                      onPressed: widget.onUnbind,
                      isLoading: widget.isUnbinding,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
