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
import 'dashboard_showcase_target.dart';

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
  late final ShowcaseView _showcaseView;
  late final int _registrationGeneration;
  bool _isShowcaseRegistered = false;

  @override
  void initState() {
    super.initState();
    _registrationGeneration = ++DashboardShowcaseScope.registrationGeneration;
    _showcaseView = ShowcaseView.register(
      scope: DashboardShowcaseScope.scope,
      enableAutoScroll: true,
      skipIfTargetNotPresent: true,
      overlayColor: AppColors.c000000,
      onFinish: _onShowcaseFinish,
      onDismiss: _onShowcaseDismiss,
      globalFloatingActionWidget: _buildGlobalFloatingActions,
    );
    DashboardShowcaseScope.activeRegistrationGeneration = _registrationGeneration;
    _isShowcaseRegistered = true;
    controller.registerShowcaseStarter(_startShowcase);
  }

  FloatingActionWidget _buildGlobalFloatingActions(BuildContext context) {
    if (!mounted || !_isShowcaseRegistered) {
      return FloatingActionWidget(
        bottom: 24.h,
        right: AppSpacing.lg.w,
        child: const SizedBox.shrink(),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return FloatingActionWidget(
      bottom: 24.h,
      right: AppSpacing.lg.w,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: _dismissShowcase,
            child: Text(
              AppStrings.dashboardTutorialSkip,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.cFFFFFF,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          FilledButton(
            onPressed: _advanceShowcase,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.c0A5943,
            ),
            child: Text(
              AppStrings.next,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.cFFFFFF,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _dismissShowcase() {
    if (!mounted || !_isShowcaseRegistered) return;
    _showcaseView.dismiss();
  }

  void _advanceShowcase() {
    if (!mounted || !_isShowcaseRegistered) return;
    _showcaseView.next();
  }

  void _startShowcase() {
    if (!mounted || !_isShowcaseRegistered) {
      controller.resetTutorialRunningState();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isShowcaseRegistered) {
        controller.resetTutorialRunningState();
        return;
      }

      _showcaseView.startShowCase(
        controller.showcaseKeys,
        delay: const Duration(milliseconds: 400),
      );
    });
  }

  void _onShowcaseFinish() {
    if (!mounted) return;
    unawaited(controller.onDashboardTutorialCompleted());
  }

  void _onShowcaseDismiss(GlobalKey? dismissedAt) {
    if (!mounted) return;
    unawaited(controller.onDashboardTutorialCompleted());
  }

  @override
  void dispose() {
    controller.unregisterShowcaseStarter();
    if (_isShowcaseRegistered &&
        _registrationGeneration == DashboardShowcaseScope.registrationGeneration) {
      _showcaseView.unregister();
      DashboardShowcaseScope.activeRegistrationGeneration = 0;
      _isShowcaseRegistered = false;
    }
    super.dispose();
  }

  Widget _buildShowcase({
    required GlobalKey showcaseKey,
    required String title,
    required String description,
    required Widget child,
  }) {
    return DashboardShowcaseTarget(
      showcaseKey: showcaseKey,
      title: title,
      description: description,
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
                      onPressed: controller.isOpeningTutorial.value
                          ? null
                          : controller.onOpenDemoTutorial,
                      isLoading: controller.isOpeningTutorial.value,
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
