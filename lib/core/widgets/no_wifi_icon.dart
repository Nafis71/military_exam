import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../constants/svg_asset.dart';
import 'app_svg_asset.dart';

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
    return AppSvgAsset(
      assetPath: SvgAsset.securityGateWifiOff,
      width: width ?? 76.w,
      height: height ?? 76.w,
      semanticsLabel: AppStrings.enableWifi,
    );
  }
}
