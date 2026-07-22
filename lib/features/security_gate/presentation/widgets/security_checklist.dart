import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

enum SecurityChecklistState { pending, checking, passed, failed }

class SecurityChecklistItemData {
  const SecurityChecklistItemData({
    required this.label,
    required this.state,
  });

  final String label;
  final SecurityChecklistState state;
}

class SecurityChecklist extends StatelessWidget {
  const SecurityChecklist({
    super.key,
    required this.items,
    this.maxHeight,
  });

  final List<SecurityChecklistItemData> items;
  final double? maxHeight;

  static List<SecurityChecklistItemData> initialCheckingItems() => [
        const SecurityChecklistItemData(
          label: AppStrings.raspRootClean,
          state: SecurityChecklistState.checking,
        ),
        if (Platform.isAndroid)
          const SecurityChecklistItemData(
            label: AppStrings.raspNoCustomRom,
            state: SecurityChecklistState.checking,
          ),
        const SecurityChecklistItemData(
          label: AppStrings.developerModeInactive,
          state: SecurityChecklistState.checking,
        ),
        const SecurityChecklistItemData(
          label: AppStrings.airplaneModeActive,
          state: SecurityChecklistState.pending,
        ),
        const SecurityChecklistItemData(
          label: AppStrings.wifiConnected,
          state: SecurityChecklistState.pending,
        ),
        const SecurityChecklistItemData(
          label: AppStrings.networkLockdownActive,
          state: SecurityChecklistState.pending,
        ),
      ];

  static List<SecurityChecklistItemData> fromIntegrity({
    required DeviceIntegrityStatus integrity,
    required bool blockEmulator,
    bool? airplaneEnabled,
    bool? wifiOnline,
    bool? vpnLockdownActive,
    SecurityChecklistState pendingTailState = SecurityChecklistState.pending,
  }) {
    SecurityChecklistState stateFor(bool passed) =>
        passed ? SecurityChecklistState.passed : SecurityChecklistState.failed;

    return [
      SecurityChecklistItemData(
        label: AppStrings.raspRootClean,
        state: stateFor(!integrity.isRooted && !integrity.isJailbroken),
      ),
      if (Platform.isAndroid)
        SecurityChecklistItemData(
          label: AppStrings.raspNoCustomRom,
          state: stateFor(!integrity.isCustomRom),
        ),
      SecurityChecklistItemData(
        label: AppStrings.developerModeInactive,
        state: stateFor(!integrity.isDeveloperModeEnabled),
      ),
      SecurityChecklistItemData(
        label: AppStrings.airplaneModeActive,
        state: airplaneEnabled == null
            ? pendingTailState
            : stateFor(airplaneEnabled),
      ),
      SecurityChecklistItemData(
        label: AppStrings.wifiConnected,
        state: wifiOnline == null ? pendingTailState : stateFor(wifiOnline),
      ),
      SecurityChecklistItemData(
        label: AppStrings.networkLockdownActive,
        state: vpnLockdownActive == null
            ? pendingTailState
            : stateFor(vpnLockdownActive),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight ?? 280.h,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ChecklistRow(label: item.label, state: item.state);
        },
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.state});

  final String label;
  final SecurityChecklistState state;

  @override
  Widget build(BuildContext context) {
    final indicator = switch (state) {
      SecurityChecklistState.pending => _PendingIndicator(),
      SecurityChecklistState.checking => SizedBox(
          width: 28.w,
          height: 28.w,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              color: AppColors.primary,
            ),
          ),
        ),
      SecurityChecklistState.passed => _ResultIndicator(
          color: AppColors.c1D8A57,
          symbol: '✓',
        ),
      SecurityChecklistState.failed => _ResultIndicator(
          color: AppColors.error,
          symbol: '✕',
        ),
    };

    final labelColor = switch (state) {
      SecurityChecklistState.pending => AppColors.c474E5A,
      SecurityChecklistState.checking => AppColors.c0F3D2E,
      SecurityChecklistState.passed => AppColors.c0F3D2E,
      SecurityChecklistState.failed => AppColors.error,
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.cEAF4EF,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        children: [
          indicator,
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                    height: 21 / 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultIndicator extends StatelessWidget {
  const _ResultIndicator({required this.color, required this.symbol});

  final Color color;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14.r),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.cFFFFFF,
              height: 1,
            ),
      ),
    );
  }
}

class _PendingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: AppColors.cFFFFFF,
        border: Border.all(color: AppColors.cBDBDBD),
        borderRadius: BorderRadius.circular(14.r),
      ),
    );
  }
}
