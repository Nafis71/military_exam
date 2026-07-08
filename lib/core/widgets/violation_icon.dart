import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../constants/png_asset.dart';
import 'app_png_asset.dart';

/// Security shield icon shown on violation and lock screens.
class ViolationIcon extends StatelessWidget {
  const ViolationIcon({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return AppPngAsset(
      assetPath: PngAsset.securityShield,
      width: width ?? 200.w,
      height: height ?? 200.h,
      semanticLabel: AppStrings.securityViolation,
    );
  }
}
