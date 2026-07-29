import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/features/exam_session/data/datasources/demo_exam_memory_store.dart';
import 'package:military_exam/features/exam_session/data/models/exam_answer_draft_model.dart';
import 'package:military_exam/features/exam_session/domain/utils/finalize_payload_builder.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  group('FinalizePayloadBuilder', () {
    test('descriptive draft without image is excluded from recovery', () {
      const draft = ExamAnswerDraftModel(
        questionId: 'written-1',
        type: ExamQuestionType.descriptive,
        questionNumber: 1,
      );

      expect(
        FinalizePayloadBuilder.shouldIncludeDraftForRecovery(
          draft,
          questionIdsWithImages: const {},
        ),
        isFalse,
      );
    });

    test('descriptive draft with image is included for recovery', () {
      const draft = ExamAnswerDraftModel(
        questionId: 'written-1',
        type: ExamQuestionType.descriptive,
        questionNumber: 1,
      );

      expect(
        FinalizePayloadBuilder.shouldIncludeDraftForRecovery(
          draft,
          questionIdsWithImages: {'written-1'},
        ),
        isTrue,
      );
    });
  });

  group('DemoExamMemoryStore', () {
    test('clear removes drafts and images', () {
      final store = DemoExamMemoryStore();
      store.upsertDraft(
        const ExamAnswerDraftModel(
          questionId: 'mcq-1',
          type: ExamQuestionType.mcq,
          optionKey: 'a',
          questionNumber: 1,
        ),
      );

      store.clear();

      expect(store.drafts, isEmpty);
      expect(store.images, isEmpty);
      expect(store.session, isNull);
    });
  });
}
