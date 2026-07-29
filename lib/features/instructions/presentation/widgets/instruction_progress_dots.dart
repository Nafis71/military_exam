import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class InstructionProgressDots extends StatelessWidget {
  const InstructionProgressDots({
    super.key,
    required this.count,
    required this.currentIndex,
    this.useLightText = false,
  });

  final int count;
  final int currentIndex;
  final bool useLightText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: useLightText
                ? (isActive
                    ? AppColors.cFFFFFF
                    : AppColors.cFFFFFF.withValues(alpha: 0.4))
                : (isActive
                    ? AppColors.instructionDotActive
                    : AppColors.instructionDotInactive),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
