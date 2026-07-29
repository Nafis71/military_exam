import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../models/exam_session_model.dart';
import '../models/fill_blank_answer_model.dart';
import '../models/mcq_answer_model.dart';

abstract class ExamLocalDataSource {
  Future<Result<void>> saveExamSession(ExamSessionModel session);

  Future<Result<ExamSessionModel?>> readExamSession();

  Future<Result<void>> saveMcqAnswer(McqAnswerModel answer);

  Future<Result<Map<String, String>>> readMcqAnswers();

  Future<Result<void>> saveFillBlankAnswer(FillBlankAnswerModel answer);

  Future<Result<Map<String, String>>> readFillBlankAnswers();

  Future<Result<void>> setExamLocked(bool locked, {String? reason});

  Future<Result<ExamLockState>> readLockState();

  Future<Result<void>> clearLegacyAnswerData();
}

class ExamLocalDataSourceImpl implements ExamLocalDataSource {
  ExamLocalDataSourceImpl(this._box);

  final Box<dynamic> _box;

  static const _examSessionKey = 'exam_session';
  static const _mcqAnswersKey = 'mcq_answers';
  static const _fillBlankAnswersKey = 'fill_blank_answers';
  static const _examLockedKey = 'exam_locked';
  static const _lockReasonKey = 'exam_lock_reason';
  static const _lockedAtKey = 'exam_locked_at';
  static const _writtenExamImagesKey = 'written_exam_images';

  @override
  Future<Result<void>> saveExamSession(ExamSessionModel session) async {
    try {
      await _box.put(_examSessionKey, jsonEncode(session.toJson()));
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToSaveExamSession}: $error'),
      );
    }
  }

  @override
  Future<Result<ExamSessionModel?>> readExamSession() async {
    try {
      final raw = _box.get(_examSessionKey) as String?;
      if (raw == null) return const Success(null);
      return Success(
        ExamSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToReadExamSession}: $error'),
      );
    }
  }

  @override
  Future<Result<void>> saveMcqAnswer(McqAnswerModel answer) async {
    try {
      final current = await readMcqAnswers();
      final answers = Map<String, String>.from(current.dataOrNull ?? {});
      answers[answer.questionId] = answer.selectedOptionId;
      await _box.put(_mcqAnswersKey, jsonEncode(answers));
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToSaveMcqAnswer}: $error'),
      );
    }
  }

  @override
  Future<Result<Map<String, String>>> readMcqAnswers() async {
    try {
      final raw = _box.get(_mcqAnswersKey) as String?;
      if (raw == null) return Success(<String, String>{});
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return Success(
        Map<String, String>.from(
          decoded.map((key, value) => MapEntry(key, value.toString())),
        ),
      );
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToReadMcqAnswers}: $error'),
      );
    }
  }

  @override
  Future<Result<void>> saveFillBlankAnswer(FillBlankAnswerModel answer) async {
    try {
      final current = await readFillBlankAnswers();
      final answers = Map<String, String>.from(current.dataOrNull ?? {});
      answers[answer.questionId] = answer.text;
      await _box.put(_fillBlankAnswersKey, jsonEncode(answers));
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToSaveFillBlankAnswer}: $error'),
      );
    }
  }

  @override
  Future<Result<Map<String, String>>> readFillBlankAnswers() async {
    try {
      final raw = _box.get(_fillBlankAnswersKey) as String?;
      if (raw == null) return Success(<String, String>{});
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return Success(
        Map<String, String>.from(
          decoded.map((key, value) => MapEntry(key, value.toString())),
        ),
      );
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToReadFillBlankAnswers}: $error'),
      );
    }
  }

  @override
  Future<Result<void>> setExamLocked(bool locked, {String? reason}) async {
    try {
      await _box.put(_examLockedKey, locked.toString());
      if (reason != null) {
        await _box.put(_lockReasonKey, reason);
      }
      if (locked) {
        await _box.put(_lockedAtKey, DateTime.now().toIso8601String());
      }
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToSetLockState}: $error'),
      );
    }
  }

  @override
  Future<Result<void>> clearLegacyAnswerData() async {
    try {
      await _box.delete(_mcqAnswersKey);
      await _box.delete(_fillBlankAnswersKey);
      await _box.delete(_writtenExamImagesKey);
      await _box.delete(_examSessionKey);
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToClearAnswerDrafts}: $error'),
      );
    }
  }

  @override
  Future<Result<ExamLockState>> readLockState() async {
    try {
      final lockedRaw = _box.get(_examLockedKey) as String?;
      final isLocked = lockedRaw == 'true';
      final reason = _box.get(_lockReasonKey) as String?;
      final lockedAtRaw = _box.get(_lockedAtKey) as String?;
      return Success(
        ExamLockState(
          isLocked: isLocked,
          reason: reason,
          lockedAt:
              lockedAtRaw != null ? DateTime.tryParse(lockedAtRaw) : null,
        ),
      );
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToReadLockState}: $error'),
      );
    }
  }
}
