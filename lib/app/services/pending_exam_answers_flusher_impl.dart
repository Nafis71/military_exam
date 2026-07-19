import 'package:get/get.dart';

import '../../core/logging/app_logger.dart';
import '../../features/exam_session/domain/ports/pending_exam_answers_flusher.dart';
import '../../features/fill_blank_exam/presentation/controllers/fill_blank_exam_controller.dart';
import '../../features/mcq_exam/presentation/controllers/mcq_exam_controller.dart';
import '../../features/written_exam/presentation/controllers/written_exam_controller.dart';
import '../../shared/domain/enums/exam_enums.dart';

class PendingExamAnswersFlusherImpl implements PendingExamAnswersFlusher {
  PendingExamAnswersFlusherImpl(this._logger);

  final AppLogger _logger;

  @override
  Future<void> flush(ExamPhase phase) async {
    switch (phase) {
      case ExamPhase.mcq:
        await _flushMcq();
      case ExamPhase.fillBlank:
        await _flushFillBlank();
      case ExamPhase.written:
        await _flushWritten();
      case ExamPhase.splash:
      case ExamPhase.instructions:
      case ExamPhase.login:
      case ExamPhase.securityGate:
      case ExamPhase.locked:
      case ExamPhase.finished:
        break;
    }
  }

  Future<void> _flushMcq() async {
    if (!Get.isRegistered<McqExamController>()) return;
    try {
      await Get.find<McqExamController>().flushPendingAnswer();
    } catch (error, stackTrace) {
      _logger.error(
        'flushPendingAnswer failed for MCQ',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _flushFillBlank() async {
    if (!Get.isRegistered<FillBlankExamController>()) return;
    try {
      await Get.find<FillBlankExamController>().flushPendingAnswer();
    } catch (error, stackTrace) {
      _logger.error(
        'flushPendingAnswer failed for fill blank',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _flushWritten() async {
    if (!Get.isRegistered<WrittenExamController>()) return;
    try {
      await Get.find<WrittenExamController>().flushPendingAnswer();
    } catch (error, stackTrace) {
      _logger.error(
        'flushPendingAnswer failed for written',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
