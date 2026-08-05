import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class DashboardDeviceRegistrationNote extends StatefulWidget {
  const DashboardDeviceRegistrationNote({super.key});

  @override
  State<DashboardDeviceRegistrationNote> createState() =>
      _DashboardDeviceRegistrationNoteState();
}

class _DashboardDeviceRegistrationNoteState
    extends State<DashboardDeviceRegistrationNote> {
  bool _isExpanded = false;

  String get _resetNote {
    if (!kIsWeb && Platform.isIOS) {
      return AppStrings.deviceRegistrationResetNoteIos;
    }
    return AppStrings.deviceRegistrationResetNoteAndroid;
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final noteStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.cFFFFFF,
      fontWeight: FontWeight.w600,
    );
    final detailStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.cFFFFFF.withValues(alpha: 0.8),
    );
    final expandLabel = _isExpanded
        ? AppStrings.deviceBindingHideDetails
        : AppStrings.deviceBindingShowDetails;

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
                      child: Text(
                        AppStrings.deviceRegistrationRegisteredNote,
                        style: noteStyle,
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
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    AppStrings.deviceRegistrationBringDeviceNote,
                    style: noteStyle,
                  ),
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    _resetNote,
                    style: detailStyle,
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
