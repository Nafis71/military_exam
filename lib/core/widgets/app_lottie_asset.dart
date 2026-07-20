import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Reusable Lottie asset loader with dynamic sizing.
class AppLottieAsset extends StatelessWidget {
  const AppLottieAsset({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.repeat = true,
    this.semanticsLabel,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final bool repeat;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
    );
  }
}
