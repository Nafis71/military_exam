import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../constants/svg_asset.dart';
import 'app_svg_asset.dart';

/// Verified user shield icon shown when security checks pass.
class VerifiedUserIcon extends StatelessWidget {
  const VerifiedUserIcon({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return AppSvgAsset(
      assetPath: SvgAsset.securityGateVerifiedUser,
      width: width ?? 76.w,
      height: height ?? 76.w,
      semanticsLabel: AppStrings.securityChecksPassed,
    );
  }
}
