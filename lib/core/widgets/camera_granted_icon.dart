import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../constants/svg_asset.dart';
import 'app_svg_asset.dart';

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
    return AppSvgAsset(
      assetPath: SvgAsset.securityGateCameraGranted,
      width: width ?? 76.w,
      height: height ?? 76.w,
      semanticsLabel: AppStrings.cameraPermissionGrantedTitle,
    );
  }
}
