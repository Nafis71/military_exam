import 'package:flutter/material.dart';

import '../constants/png_asset.dart';

/// Reusable PNG asset loader with dynamic sizing and styling.
class AppPngAsset extends StatelessWidget {
  const AppPngAsset({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.opacity,
    this.semanticLabel,
    this.cacheWidth,
    this.cacheHeight,
    this.errorBuilder,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;
  final double? opacity;
  final String? semanticLabel;
  final int? cacheWidth;
  final int? cacheHeight;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      opacity: opacity != null ? AlwaysStoppedAnimation(opacity!) : null,
      semanticLabel: semanticLabel,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: errorBuilder ??
          (context, error, stackTrace) => Icon(
                Icons.image_not_supported_outlined,
                size: width ?? height ?? 48,
                color: color,
              ),
    );

    return image;
  }
}

/// Branded app logo using centralized PNG asset constant.
class AppLogoView extends StatelessWidget {
  const AppLogoView({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return AppPngAsset(
      assetPath: PngAsset.appLogo,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: 'Military Examination App Logo',
    );
  }
}
