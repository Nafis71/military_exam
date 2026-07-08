import 'package:get/get.dart';

import '../../shared/domain/entities/exam_entities.dart';

class ExamLockService extends GetxService {
  final Rx<ExamLockState> lockState =
      const ExamLockState(isLocked: false).obs;

  bool get isLocked => lockState.value.isLocked;

  Future<void> lock({required String reason}) async {
    lockState.value = ExamLockState(
      isLocked: true,
      reason: reason,
      lockedAt: DateTime.now(),
    );
  }

  void unlock() {
    lockState.value = const ExamLockState(isLocked: false);
  }
}
