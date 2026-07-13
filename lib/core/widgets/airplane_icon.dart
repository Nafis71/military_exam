import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../constants/svg_asset.dart';
import 'app_svg_asset.dart';

/// Airplane icon shown on the airplane mode security gate screen.
class AirplaneIcon extends StatelessWidget {
  const AirplaneIcon({
    super.key,
    this.width,
    this.height,
    this.isEnabled = false,
  });

  final double? width;
  final double? height;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return AppSvgAsset(
      assetPath: isEnabled
          ? SvgAsset.securityGateAirplaneModeActive
          : SvgAsset.securityGateAirplaneModeInactive,
      width: width ?? 76.w,
      height: height ?? 76.w,
      semanticsLabel: isEnabled
          ? AppStrings.airplaneModeEnabled
          : AppStrings.enableAirplaneMode,
    );
  }
}
