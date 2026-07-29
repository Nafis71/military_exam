import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_answers_hive_datasource.dart';
import 'package:military_exam/features/exam_session/data/models/exam_answer_draft_model.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  late Directory hiveTestDir;
  late Box<dynamic> box;
  late ExamAnswersHiveDataSourceImpl dataSource;

  setUp(() async {
    hiveTestDir = Directory(
      '${Directory.systemTemp.path}/military_exam_hive_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    await hiveTestDir.create(recursive: true);
    Hive.init(hiveTestDir.path);
    box = await Hive.openBox<dynamic>('exam_answers_test');
    dataSource = ExamAnswersHiveDataSourceImpl(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (hiveTestDir.existsSync()) {
      await hiveTestDir.delete(recursive: true);
    }
  });

  test('ExamAnswersHiveDataSource saves roll number and drafts', () async {
    final saveRoll = await dataSource.saveRollNumber('123456');
    expect(saveRoll, isA<Success<void>>());

    final draft = ExamAnswerDraftModel(
      questionId: 'mcq-1',
      type: ExamQuestionType.mcq,
      optionKey: 'a',
      questionNumber: 1,
    );
    final saveDraft = await dataSource.upsertDraft(draft);
    expect(saveDraft, isA<Success<void>>());

    final rollResult = await dataSource.readRollNumber();
    expect(rollResult.dataOrNull, '123456');

    final draftsResult = await dataSource.readAllDrafts();
    expect(draftsResult.dataOrNull?['mcq-1']?.optionKey, 'a');
  });

  test('ExamAnswersHiveDataSource reads draft when question_id is missing', () async {
    await box.put(
      ExamAnswersHiveDataSourceImpl.draftsKey,
      jsonEncode({
        'mcq-legacy': {
          'type': 'mcq',
          'option_key': 'b',
        },
      }),
    );

    final draftsResult = await dataSource.readAllDrafts();
    expect(draftsResult, isA<Success<Map<String, ExamAnswerDraftModel>>>());
    expect(draftsResult.dataOrNull?['mcq-legacy']?.questionId, 'mcq-legacy');
    expect(draftsResult.dataOrNull?['mcq-legacy']?.optionKey, 'b');
  });

  test('ExamAnswersHiveDataSource reads legacy string mcq drafts', () async {
    await box.put(
      ExamAnswersHiveDataSourceImpl.draftsKey,
      jsonEncode({'mcq-legacy': 'c'}),
    );

    final draftsResult = await dataSource.readAllDrafts();
    expect(draftsResult.dataOrNull?['mcq-legacy']?.questionId, 'mcq-legacy');
    expect(draftsResult.dataOrNull?['mcq-legacy']?.optionKey, 'c');
  });

  test('ExamAnswersHiveDataSource clearAll wipes drafts but preserves roll number', () async {
    await dataSource.saveRollNumber('999');
    await dataSource.upsertDraft(
      const ExamAnswerDraftModel(
        questionId: 'fill-1',
        type: ExamQuestionType.fillInBlank,
        answerText: 'text',
      ),
    );

    final clearResult = await dataSource.clearAll();
    expect(clearResult, isA<Success<void>>());

    final rollResult = await dataSource.readRollNumber();
    expect(rollResult.dataOrNull, '999');

    final draftsResult = await dataSource.readAllDrafts();
    expect(draftsResult.dataOrNull, isEmpty);
  });
}
