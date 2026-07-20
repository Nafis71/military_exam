import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/lottie_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_lottie_asset.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/exam_connectivity_snackbar_listener.dart';
import '../../../../core/widgets/typewriter_text.dart';
import '../../domain/entities/exam_submit_summary.dart';
import '../controllers/exam_submit_review_controller.dart';
import '../controllers/exam_submit_review_state.dart';
import '../widgets/exam_submit_summary_card.dart';

class ExamSubmitReviewPage extends GetView<ExamSubmitReviewController> {
  const ExamSubmitReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ExamConnectivitySnackBarListener(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Obx(() {
              final state = controller.reviewState.value;

              return switch (state.viewState) {
                ExamSubmitReviewViewState.loading => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.c176B4D,
                    ),
                  ),
                ExamSubmitReviewViewState.waitingForNetwork =>
                  _WaitingView(
                    waitingErrorMessage: state.waitingErrorMessage,
                    stopAutoRetry: state.stopAutoRetry,
                    onRetry: controller.retrySubmit,
                    isSubmitting: controller.isSubmitting.value,
                  ),
                ExamSubmitReviewViewState.summary => _SummaryView(
                    textTheme: textTheme,
                    summary: controller.summary.value,
                    syncWarning: state.syncWarning,
                    errorMessage: state.errorMessage,
                    canSubmit: controller.canSubmitExam,
                    isSubmitting: controller.isSubmitting.value,
                    isRefreshing: controller.isRefreshing.value,
                    onSubmit: controller.submit,
                    onRefresh: controller.refreshSummary,
                  ),
              };
            }),
          ),
        ),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.textTheme,
    required this.summary,
    required this.syncWarning,
    required this.errorMessage,
    required this.canSubmit,
    required this.isSubmitting,
    required this.isRefreshing,
    required this.onSubmit,
    required this.onRefresh,
  });

  final TextTheme textTheme;
  final ExamSubmitSummary? summary;
  final String? syncWarning;
  final String? errorMessage;
  final bool canSubmit;
  final bool isSubmitting;
  final bool isRefreshing;
  final VoidCallback onSubmit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppStrings.examSubmitReviewTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.c0F3D2E,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
                if (summary != null) ExamSubmitSummaryCard(summary: summary!),
                if (syncWarning != null) ...[
                  SizedBox(height: AppSpacing.md.h),
                  Text(
                    syncWarning!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.c66736C,
                    ),
                  ),
                ],
                if (errorMessage != null) ...[
                  SizedBox(height: AppSpacing.md.h),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.c66736C,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AppPrimaryButton(
                    label: AppStrings.examSubmitReviewRetry,
                    isLoading: isRefreshing,
                    onPressed: isRefreshing ? null : onRefresh,
                  ),
                ],
                if (!canSubmit) ...[
                  SizedBox(height: AppSpacing.md.h),
                  Text(
                    AppStrings.cannotSubmitYet,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.c66736C,
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.xl.h),
                AppPrimaryButton(
                  label: AppStrings.examSubmitReviewSubmit,
                  isLoading: isSubmitting,
                  onPressed: canSubmit && !isSubmitting ? onSubmit : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({
    required this.waitingErrorMessage,
    required this.stopAutoRetry,
    required this.onRetry,
    required this.isSubmitting,
  });

  final String? waitingErrorMessage;
  final bool stopAutoRetry;
  final VoidCallback onRetry;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppLottieAsset(
              assetPath: LottieAsset.noConnection,
              width: 160.w,
              height: 160.w,
              repeat: true,
            ),
            SizedBox(height: AppSpacing.lg.h),
            Text(
              AppStrings.examSubmitReviewWaitingTitle,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.c0F3D2E,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            TypewriterText(
              text: AppStrings.examSubmitReviewOfflineMessage,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.c66736C,
              ),
              textAlign: TextAlign.center,
              repeat: true,
            ),
            if (waitingErrorMessage != null) ...[
              SizedBox(height: AppSpacing.lg.h),
              Text(
                waitingErrorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.c66736C,
                ),
              ),
            ],
            if (stopAutoRetry) ...[
              SizedBox(height: AppSpacing.lg.h),
              AppPrimaryButton(
                label: AppStrings.examSubmitReviewRetry,
                isLoading: isSubmitting,
                onPressed: isSubmitting ? null : onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
