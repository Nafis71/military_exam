import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/svg_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_svg_asset.dart';

/// Concentric success rings with checkmark, matching Figma node 4:2553.
/// Outer ring pulses gently; middle, core, and check stay static.
class FinishExamSuccessIcon extends StatefulWidget {
  const FinishExamSuccessIcon({super.key});

  @override
  State<FinishExamSuccessIcon> createState() => _FinishExamSuccessIconState();
}

class _FinishExamSuccessIconState extends State<FinishExamSuccessIcon>
    with SingleTickerProviderStateMixin {
  static const Duration _pulseDuration = Duration(milliseconds: 1600);

  late final AnimationController _controller;
  late final Animation<double> _outerScale;
  late final Animation<double> _outerOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _pulseDuration);
    _outerScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _outerOpacity = Tween<double>(begin: 1.0, end: 0.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160.w,
      height: 160.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _outerOpacity.value,
                child: Transform.scale(
                  scale: _outerScale.value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 160.w,
              height: 160.w,
              decoration: BoxDecoration(
                color: AppColors.c23966A.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(80.r),
              ),
            ),
          ),
          Container(
            width: 130.w,
            height: 130.w,
            decoration: BoxDecoration(
              color: AppColors.c23966A.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(65.r),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: AppColors.c176B4D,
                borderRadius: BorderRadius.circular(50.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.c176B4D.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: AppSvgAsset(
                assetPath: SvgAsset.examSuccessCheck,
                width: 48.w,
                height: 48.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
