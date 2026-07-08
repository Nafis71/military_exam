import 'package:get/get.dart';

import '../../shared/domain/entities/exam_entities.dart';

enum ExamConnectivityAlertType {
  none,
  noInternet,
  unstable,
}

/// Tracks mid-exam connectivity changes and surfaces non-penalizing alerts.
class ExamConnectivityAlertService extends GetxService {
  static const _flapWindow = Duration(seconds: 30);
  static const _flapThreshold = 2;

  final Rx<ExamConnectivityAlertType> alert =
      ExamConnectivityAlertType.none.obs;

  final List<DateTime> _recentChanges = [];

  void onConnectivityChanged(ConnectivityStatus status) {
    final now = DateTime.now();
    _recentChanges.add(now);
    _recentChanges.removeWhere(
      (timestamp) => now.difference(timestamp) > _flapWindow,
    );

    if (status.isOnline) {
      alert.value = ExamConnectivityAlertType.none;
      return;
    }

    alert.value = _recentChanges.length >= _flapThreshold
        ? ExamConnectivityAlertType.unstable
        : ExamConnectivityAlertType.noInternet;
  }

  void reset() {
    _recentChanges.clear();
    alert.value = ExamConnectivityAlertType.none;
  }
}
