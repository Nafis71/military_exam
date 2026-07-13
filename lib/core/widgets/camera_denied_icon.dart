import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../constants/svg_asset.dart';
import 'app_svg_asset.dart';

/// Camera denied icon shown on the camera permission security gate screen.
class CameraDeniedIcon extends StatelessWidget {
  const CameraDeniedIcon({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return AppSvgAsset(
      assetPath: SvgAsset.securityGateCameraDenied,
      width: width ?? 76.w,
      height: height ?? 76.w,
      semanticsLabel: AppStrings.enableCameraPermission,
    );
  }
}
