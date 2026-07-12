import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';

import 'written_exam_success_banner.dart';

/// Figma 4:2429 success toast shown when a written answer image is added.
class WrittenExamImageAddedToast {
  WrittenExamImageAddedToast._();

  static const Duration _duration = Duration(seconds: 3);

  static void show() {
    showOverlayNotification(
      (context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
          child: const WrittenExamSuccessBanner(),
        ),
      ),
      duration: _duration,
      position: NotificationPosition.top,
    );
  }
}
