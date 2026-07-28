import 'dart:async';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/system_ui_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

typedef QrDetectCallback = Future<void> Function(String rawValue);

class IdentityQrScannerPage extends StatefulWidget {
  const IdentityQrScannerPage({
    super.key,
    required this.onDetect,
  });

  final QrDetectCallback onDetect;

  @override
  State<IdentityQrScannerPage> createState() => _IdentityQrScannerPageState();
}

class _IdentityQrScannerPageState extends State<IdentityQrScannerPage> {
  late final MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    _isProcessing = true;
    try {
      await widget.onDetect(rawValue);
    } catch (e, st) {
      if (kDebugMode) {
        Get.find<AppLogger>().error(
          'identity QR onDetect failed',
          error: e,
          stackTrace: st,
        );
      }
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AiBarcodeScanner(
      controller: _controller,
      galleryButtonType: GalleryButtonType.none,
      setPortraitOrientation: false,
      onDispose: () {
        unawaited(SystemUiService.applyPortraitLock());
      },
      useAppLifecycleState: true,
      overlayConfig: ScannerOverlayConfig(
        animationColor: AppColors.c89D5B2,
        borderColor: AppColors.c0A5943,
        successColor: AppColors.c16A34A,
        errorColor: AppColors.cDC2626,
      ),
      onDetect: (capture) => unawaited(_handleDetect(capture)),
      errorBuilder: (context, error) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.c0F3D2E),
              onPressed: Get.back,
            ),
          ),
          body: Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: Center(
              child: Text(
                AppStrings.qrScannerError,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.c474E5A,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
