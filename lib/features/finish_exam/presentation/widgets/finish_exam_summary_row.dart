import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

/// Single label/value row inside the finish-exam summary card.
class FinishExamSummaryRow extends StatelessWidget {
  const FinishExamSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontWeight = FontWeight.w400,
    this.showBottomBorder = true,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight valueFontWeight;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 12.h, bottom: 13.h),
      decoration: showBottomBorder
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.cD9E5DE),
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.c66736C,
              height: 19.5 / 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: valueFontWeight,
                color: valueColor ?? AppColors.c17231D,
                height: 21 / 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
