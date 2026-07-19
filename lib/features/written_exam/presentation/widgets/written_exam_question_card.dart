import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/svg_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_svg_asset.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import 'written_exam_capture_card.dart';
import 'written_exam_image_card.dart';

class WrittenExamQuestionCard extends StatelessWidget {
  const WrittenExamQuestionCard({
    super.key,
    required this.question,
    required this.images,
    this.isLocked = false,
    required this.onAddImage,
    required this.onReplace,
    required this.onDelete,
  });

  final WrittenQuestion question;
  final List<WrittenAnswerImage> images;
  final bool isLocked;
  final VoidCallback onAddImage;
  final Function(String localId) onReplace;
  final Function(String localId) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.c0F3D2E.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.cEAF4EF,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${AppStrings.questionOf} ${toBengaliDigits(question.index)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.c176B4D,
                          height: 19.5 / 13,
                        ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  question.text,
                  softWrap: true,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.c17231D,
                        height: 1.6,
                      ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cEAF4EF,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        AppStrings.writtenExamAnswerLabel,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.c176B4D,
                                  height: 19.5 / 13,
                                ),
                      ),
                    ),
                    const Spacer(),
                    if (images.isEmpty && !isLocked)
                      GestureDetector(
                        onTap: onAddImage,
                        child: AppSvgAsset(
                          assetPath: SvgAsset.writtenExamAdd,
                          width: 24.w,
                          height: 24.w,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (images.isEmpty && !isLocked)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: WrittenExamCaptureCard(onTap: onAddImage),
            )
          else
            Column(
              children: images.asMap().entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w)
                      .add(EdgeInsets.only(bottom: entry.key == images.length - 1 ? 20.h : 0)),
                  child: WrittenExamImageCard(
                    image: entry.value,
                    pageNumber: entry.key + 1,
                    nested: true,
                    isLocked: isLocked,
                    onReplace: () => onReplace(entry.value.localId),
                    onDelete: () => onDelete(entry.value.localId),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
