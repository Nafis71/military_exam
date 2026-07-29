import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/png_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_png_asset.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../constants/dashboard_showcase_scope.dart';
import '../controllers/candidate_dashboard_controller.dart';
import 'dashboard_exam_banner.dart';
import 'dashboard_notification_icon_button.dart';
import 'dashboard_profile_card.dart';
import 'dashboard_settings_icon_button.dart';

class CandidateDashboardShowcaseHost extends StatefulWidget {
  const CandidateDashboardShowcaseHost({
    super.key,
    required this.controller,
  });

  final CandidateDashboardController controller;

  @override
  State<CandidateDashboardShowcaseHost> createState() =>
      _CandidateDashboardShowcaseHostState();
}

class _CandidateDashboardShowcaseHostState
    extends State<CandidateDashboardShowcaseHost> {
  CandidateDashboardController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    ShowcaseView.register(
      scope: DashboardShowcaseScope.scope,
      enableAutoScroll: true,
      skipIfTargetNotPresent: true,
      overlayColor: AppColors.c000000,
      onStart: _onShowcaseStart,
      onFinish: _onShowcaseFinish,
      onDismiss: _onShowcaseDismiss,
      globalFloatingActionWidget: (context) => FloatingActionWidget(
        bottom: 24.h,
        right: AppSpacing.lg.w,
        child: TextButton(
          onPressed: () =>
              ShowcaseView.getNamed(DashboardShowcaseScope.scope).dismiss(),
          child: Text(
            AppStrings.dashboardTutorialSkip,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.cFFFFFF,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
    controller.registerShowcaseStarter(_startShowcase);
  }

  void _startShowcase() {
    ShowcaseView.getNamed(DashboardShowcaseScope.scope).startShowCase(
      controller.showcaseKeys,
      delay: const Duration(milliseconds: 400),
    );
  }

  void _onShowcaseStart(int? index, GlobalKey key) {
    if (key == controller.deviceInfoShowcaseKey) {
      controller.isDeviceBindingExpanded.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.scrollController.hasClients) return;
        unawaited(
          controller.scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        );
      });
    }
  }

  void _onShowcaseFinish() {
    unawaited(controller.markDashboardTutorialSeen());
  }

  void _onShowcaseDismiss(GlobalKey? dismissedAt) {
    unawaited(controller.markDashboardTutorialSeen());
  }

  @override
  void dispose() {
    controller.unregisterShowcaseStarter();
    ShowcaseView.getNamed(DashboardShowcaseScope.scope).unregister();
    super.dispose();
  }

  Widget _buildShowcase({
    required GlobalKey showcaseKey,
    required String title,
    required String description,
    required Widget child,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Showcase(
      key: showcaseKey,
      scope: DashboardShowcaseScope.scope,
      title: title,
      description: description,
      tooltipBackgroundColor: AppColors.cFFFFFF,
      textColor: AppColors.c0F3D2E,
      titleTextStyle: textTheme.titleMedium?.copyWith(
        color: AppColors.c0F3D2E,
        fontWeight: FontWeight.w700,
      ),
      descTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.c66736C),
      targetBorderRadius: BorderRadius.circular(12.r),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: EdgeInsets.only(left: AppSpacing.lg.w),
          child: Center(
            child: AppPngAsset(
              assetPath: PngAsset.appLogo,
              width: 36.w,
              height: 36.w,
            ),
          ),
        ),
        leadingWidth: 36.w + AppSpacing.lg.w + AppSpacing.sm.w,
        title: Text(
          AppStrings.candidateDashboardTitle,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.c0F3D2E,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          _buildShowcase(
            showcaseKey: controller.settingsShowcaseKey,
            title: AppStrings.dashboardTutorialSettingsTitle,
            description: AppStrings.dashboardTutorialSettingsDescription,
            child: DashboardSettingsIconButton(
              onPressed: controller.onOpenSecuritySettings,
            ),
          ),
          Obx(
            () => _buildShowcase(
              showcaseKey: controller.notificationsShowcaseKey,
              title: AppStrings.dashboardTutorialNotificationsTitle,
              description: AppStrings.dashboardTutorialNotificationsDescription,
              child: DashboardNotificationIconButton(
                unreadCount: controller.unreadNotificationCount.value,
                onPressed: controller.onOpenNotifications,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final contentKey = controller.candidate.value?.candidateId;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: controller.scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg.w,
                  AppSpacing.lg.h,
                  AppSpacing.lg.w,
                  AppSpacing.md.h,
                ),
                child: StaggeredEntrance(
                  contentKey: contentKey,
                  children: [
                    Obx(
                      () => DashboardProfileCard(
                        candidate: controller.candidate.value,
                        isDeviceBound: controller.isDeviceBound.value,
                        isUnbinding: controller.isUnbinding.value,
                        deviceBrandName: controller.deviceBrandName.value,
                        deviceModelNumber: controller.deviceModelNumber.value,
                        deviceOsVersion: controller.deviceOsVersion.value,
                        isDeviceInfoAvailable:
                            controller.isDeviceInfoAvailable.value,
                        isDeviceBindingExpanded:
                            controller.isDeviceBindingExpanded.value,
                        onDeviceBindingExpandedChanged: (isExpanded) {
                          controller.isDeviceBindingExpanded.value = isExpanded;
                        },
                        deviceInfoShowcaseKey: controller.deviceInfoShowcaseKey,
                        onUnbind: controller.onUnbind,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    _buildShowcase(
                      showcaseKey: controller.examInfoShowcaseKey,
                      title: AppStrings.dashboardTutorialExamInfoTitle,
                      description: AppStrings.dashboardTutorialExamInfoDescription,
                      child: DashboardExamBanner(
                        examInfo: controller.examInfo.value,
                        onStartExamination: controller.onStartExamination,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    _buildShowcase(
                      showcaseKey: controller.examRulesShowcaseKey,
                      title: AppStrings.dashboardTutorialExamRulesTitle,
                      description: AppStrings.dashboardTutorialExamRulesDescription,
                      child: TextButton(
                        onPressed: controller.onViewExamProcedure,
                        child: Text(
                          AppStrings.viewExaminationProcedure,
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.c0A5943,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.showStartDemo.value)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg.w,
                  AppSpacing.sm.h,
                  AppSpacing.lg.w,
                  AppSpacing.lg.h + bottomInset,
                ),
                child: StaggeredEntrance(
                  contentKey: contentKey,
                  children: [
                    Obx(
                      () => AppPrimaryButton(
                        label: AppStrings.startDemo,
                        onPressed: controller.isStartingDemo.value
                            ? null
                            : controller.onStartDemo,
                        isLoading: controller.isStartingDemo.value,
                        backgroundColor: AppColors.c66736C,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}
