import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/png_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_png_asset.dart';

class WrittenExamGalleryBanned extends StatelessWidget {
  const WrittenExamGalleryBanned({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 19.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: AppColors.cF9F9F9,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.cD9E5DE),
        ),
        child: Row(
          children: [
            AppPngAsset(
              assetPath: PngAsset.writtenExamGalleryBanned,
              width: 24.w,
              height: 24.w,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.writtenExamGalleryBannedTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.c66736C,
                          height: 19.5 / 13,
                        ),
                  ),
                  Text(
                    AppStrings.writtenExamGalleryBannedSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.c66736C,
                          height: 18 / 12,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
