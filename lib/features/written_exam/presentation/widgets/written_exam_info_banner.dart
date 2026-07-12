import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/svg_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_asset.dart';

class WrittenExamInfoBanner extends StatelessWidget {
  const WrittenExamInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 19.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: AppColors.cEAF4EF,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: AppColors.cD9E5DE),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSvgAsset(
            assetPath: SvgAsset.writtenExamInfo,
            width: 18.w,
            height: 18.w,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              AppStrings.writtenExamInfo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.c0F3D2E,
                    height: 20.8 / 13,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
