import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../constants/png_asset.dart';
import 'app_png_asset.dart';

/// No-WiFi icon shown on the WiFi mode security gate screen.
class NoWifiIcon extends StatelessWidget {
  const NoWifiIcon({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return AppPngAsset(
      assetPath: PngAsset.noWifi,
      width: width ?? 200.w,
      height: height ?? 200.h,
      semanticLabel: AppStrings.enableWifi,
    );
  }
}
