import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/svg_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../controllers/instructions_controller.dart';
import '../widgets/instruction_card.dart';
import '../widgets/instruction_progress_dots.dart';

class InstructionsPage extends GetView<InstructionsController> {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: [
                InstructionCard(
                  icon: Icons.flight,
                  title: AppStrings.rule1Title,
                  description: AppStrings.rule1Description,
                ),
                InstructionCard(
                  svgAssetPath: SvgAsset.instructionScreenshotProhibited,
                  title: AppStrings.rule2Title,
                  description: AppStrings.rule2Description,
                ),
                InstructionCard(
                  svgAssetPath: SvgAsset.instructionStayInApp,
                  title: AppStrings.rule3Title,
                  description: AppStrings.rule3Description,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: Column(
              children: [
                Obx(
                  () => InstructionProgressDots(
                    count: InstructionsController.totalPages,
                    currentIndex: controller.currentPage.value,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
                Obx(
                  () => AppPrimaryButton(
                    label: controller.continueButtonLabel,
                    onPressed: controller.nextPage,
                    trailingIcon: Icons.arrow_forward,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
