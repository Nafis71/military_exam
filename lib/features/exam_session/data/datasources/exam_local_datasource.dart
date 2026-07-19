import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/storage_keys.dart';
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
}

class ExamLocalDataSourceImpl implements ExamLocalDataSource {
  ExamLocalDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const _examSessionKey = 'exam_session';
  static const _mcqAnswersKey = 'mcq_answers';
  static const _fillBlankAnswersKey = 'fill_blank_answers';
  static const _lockReasonKey = 'exam_lock_reason';
  static const _lockedAtKey = 'exam_locked_at';

  @override
  Future<Result<void>> saveExamSession(ExamSessionModel session) async {
    try {
      await _storage.write(
        key: _examSessionKey,
        value: jsonEncode(session.toJson()),
      );
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
      final raw = await _storage.read(key: _examSessionKey);
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
      await _storage.write(key: _mcqAnswersKey, value: jsonEncode(answers));
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
      final raw = await _storage.read(key: _mcqAnswersKey);
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
      await _storage.write(
        key: _fillBlankAnswersKey,
        value: jsonEncode(answers),
      );
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
      final raw = await _storage.read(key: _fillBlankAnswersKey);
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
      await _storage.write(
        key: StorageKeys.examLocked,
        value: locked.toString(),
      );
      if (reason != null) {
        await _storage.write(key: _lockReasonKey, value: reason);
      }
      if (locked) {
        await _storage.write(
          key: _lockedAtKey,
          value: DateTime.now().toIso8601String(),
        );
      }
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToSetLockState}: $error'),
      );
    }
  }

  @override
  Future<Result<ExamLockState>> readLockState() async {
    try {
      final lockedRaw = await _storage.read(key: StorageKeys.examLocked);
      final isLocked = lockedRaw == 'true';
      final reason = await _storage.read(key: _lockReasonKey);
      final lockedAtRaw = await _storage.read(key: _lockedAtKey);
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
