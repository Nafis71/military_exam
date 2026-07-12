import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_png_asset.dart';
import '../controllers/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  /// Figma frame 390×844 — seal inset ~52.5% width (~205px).
  static const double _logoSize = 205;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Center(
        child: AppLogoView(
          width: _logoSize.w,
          height: _logoSize.w,
        ),
      ),
    );
  }
}
