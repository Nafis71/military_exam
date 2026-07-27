import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shield_lock_icon.dart';
import '../../../../core/widgets/security_status_body.dart';

class DeviceCompromisedPage extends StatelessWidget {
  const DeviceCompromisedPage({super.key, this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: SecurityStatusBody(
              contentKey: 'device_compromised',
              title: AppStrings.rootedDeviceTitle,
              message: reason ?? AppStrings.deviceCompromisedGeneric,
              icon: const ShieldLockIcon(),
              iconColor: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}
