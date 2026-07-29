import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../models/exam_answer_draft_model.dart';

abstract class ExamAnswersHiveDataSource {
  Future<Result<void>> saveRollNumber(String rollNumber);

  Future<Result<String?>> readRollNumber();

  Future<Result<void>> upsertDraft(ExamAnswerDraftModel draft);

  Future<Result<Map<String, ExamAnswerDraftModel>>> readAllDrafts();

  Future<Result<void>> clearAll();
}

class ExamAnswersHiveDataSourceImpl implements ExamAnswersHiveDataSource {
  ExamAnswersHiveDataSourceImpl(this._box);

  static const boxName = 'exam_answers';
  static const rollNumberKey = '__roll_number__';
  static const draftsKey = '__drafts__';

  final Box<dynamic> _box;

  @override
  Future<Result<void>> saveRollNumber(String rollNumber) async {
    try {
      await _box.put(rollNumberKey, rollNumber);
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToSaveRollNumber}: $error'),
      );
    }
  }

  @override
  Future<Result<String?>> readRollNumber() async {
    try {
      return Success(_box.get(rollNumberKey) as String?);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToReadRollNumber}: $error'),
      );
    }
  }

  @override
  Future<Result<void>> upsertDraft(ExamAnswerDraftModel draft) async {
    try {
      final drafts = await _readDraftsMap();
      drafts[draft.questionId] = draft.toJson();
      await _box.put(draftsKey, jsonEncode(drafts));
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToSaveAnswerDraft}: $error'),
      );
    }
  }

  @override
  Future<Result<Map<String, ExamAnswerDraftModel>>> readAllDrafts() async {
    try {
      final raw = await _readDraftsMap();
      final drafts = <String, ExamAnswerDraftModel>{};
      for (final entry in raw.entries) {
        final draft = _parseDraftEntry(entry.key, entry.value);
        if (draft != null) {
          drafts[entry.key] = draft;
        }
      }
      return Success(drafts);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToReadAnswerDrafts}: $error'),
      );
    }
  }

  ExamAnswerDraftModel? _parseDraftEntry(String questionId, Object? value) {
    if (value is Map) {
      return ExamAnswerDraftModel.fromJson(
        Map<String, dynamic>.from(value),
        questionId: questionId,
      );
    }
    if (value is String) {
      return ExamAnswerDraftModel(
        questionId: questionId,
        type: ExamQuestionType.mcq,
        optionKey: value,
      );
    }
    return null;
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      final preservedRollNumber = _box.get(rollNumberKey) as String?;
      await _box.clear();
      if (preservedRollNumber != null && preservedRollNumber.isNotEmpty) {
        await _box.put(rollNumberKey, preservedRollNumber);
      }
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToClearAnswerDrafts}: $error'),
      );
    }
  }

  Future<Map<String, dynamic>> _readDraftsMap() async {
    final raw = _box.get(draftsKey);
    if (raw == null) return {};
    if (raw is String) {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    }
    return Map<String, dynamic>.from(raw as Map);
  }
}
