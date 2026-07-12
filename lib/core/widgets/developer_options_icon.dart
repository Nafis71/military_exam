import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../constants/png_asset.dart';
import 'app_png_asset.dart';

/// Developer options icon shown on the developer mode security gate screen.
class DeveloperOptionsIcon extends StatelessWidget {
  const DeveloperOptionsIcon({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return AppPngAsset(
      assetPath: PngAsset.developerMode,
      width: width ?? 76.w,
      height: height ?? 76.h,
      semanticLabel: AppStrings.disableDeveloperMode,
    );
  }
}
