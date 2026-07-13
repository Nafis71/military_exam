import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../constants/svg_asset.dart';
import 'app_svg_asset.dart';

/// WiFi-on icon shown when connectivity is enabled on the WiFi security gate.
class WifiOnIcon extends StatelessWidget {
  const WifiOnIcon({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return AppSvgAsset(
      assetPath: SvgAsset.securityGateWifiOn,
      width: width ?? 76.w,
      height: height ?? 76.w,
      semanticsLabel: AppStrings.networkConnectedContinue,
    );
  }
}
