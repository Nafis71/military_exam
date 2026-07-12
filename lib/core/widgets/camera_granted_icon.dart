import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../constants/png_asset.dart';
import 'app_png_asset.dart';

/// Camera granted icon shown when camera permission is approved.
class CameraGrantedIcon extends StatelessWidget {
  const CameraGrantedIcon({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return AppPngAsset(
      assetPath: PngAsset.cameraGranted,
      width: width ?? 76.w,
      height: height ?? 76.h,
      semanticLabel: AppStrings.cameraPermissionGrantedTitle,
    );
  }
}
