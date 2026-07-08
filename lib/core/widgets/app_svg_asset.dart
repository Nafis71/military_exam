import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable SVG asset loader with dynamic sizing and styling.
class AppSvgAsset extends StatelessWidget {
  const AppSvgAsset({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.colorFilter,
    this.color,
    this.semanticsLabel,
    this.placeholderBuilder,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final ColorFilter? colorFilter;
  final Color? color;
  final String? semanticsLabel;
  final WidgetBuilder? placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      colorFilter: colorFilter ??
          (color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null),
      semanticsLabel: semanticsLabel,
      placeholderBuilder: placeholderBuilder,
    );
  }
}
