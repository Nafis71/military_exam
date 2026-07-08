import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_strings.dart';
import '../services/exam_connectivity_alert_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shows a snackbar when mid-exam connectivity drops or becomes unstable.
class ExamConnectivitySnackBarListener extends StatefulWidget {
  const ExamConnectivitySnackBarListener({required this.child, super.key});

  final Widget child;

  @override
  State<ExamConnectivitySnackBarListener> createState() =>
      _ExamConnectivitySnackBarListenerState();
}

class _ExamConnectivitySnackBarListenerState
    extends State<ExamConnectivitySnackBarListener> {
  Worker? _alertWorker;
  ExamConnectivityAlertType? _lastShownAlert;

  @override
  void initState() {
    super.initState();
    final alertService = Get.find<ExamConnectivityAlertService>();
    _alertWorker = ever(alertService.alert, _onAlertChanged);
  }

  void _onAlertChanged(ExamConnectivityAlertType alert) {
    if (!mounted) return;

    if (alert == ExamConnectivityAlertType.none) {
      _lastShownAlert = null;
      return;
    }

    if (alert == _lastShownAlert) return;
    _lastShownAlert = alert;

    final message = switch (alert) {
      ExamConnectivityAlertType.noInternet => AppStrings.noInternetConnection,
      ExamConnectivityAlertType.unstable =>
        AppStrings.unstableInternetDuringExam,
      ExamConnectivityAlertType.none => '',
    };

    if (message.isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.cFFFFFF),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    _alertWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
