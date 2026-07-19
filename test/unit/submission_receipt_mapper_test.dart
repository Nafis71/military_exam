import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/constants/app_strings.dart';
import 'package:military_exam/features/exam_session/data/mappers/submission_receipt_mapper.dart';

void main() {
  group('SubmissionReceiptMapper', () {
    test('parses full receipt json', () {
      final receipt = SubmissionReceiptMapper.fromJson({
        'submission_id': 'sub-123',
        'submitted_at': '2026-07-19T17:50:00.000Z',
        'message': 'ok',
      });

      expect(receipt.submissionId, 'sub-123');
      expect(receipt.submittedAt.toUtc().toIso8601String(),
          '2026-07-19T17:50:00.000Z');
      expect(receipt.message, 'ok');
    });

    test('accepts id when submission_id is missing', () {
      final receipt = SubmissionReceiptMapper.fromJson({
        'id': 'alt-id',
        'message': 'done',
      });

      expect(receipt.submissionId, 'alt-id');
      expect(receipt.message, 'done');
    });

    test('falls back when submission_id and submitted_at are null', () {
      final before = DateTime.now();
      final receipt = SubmissionReceiptMapper.fromJson({
        'message': 'Exam finalized',
      });
      final after = DateTime.now();

      expect(receipt.submissionId, startsWith('sub-'));
      expect(
        receipt.submittedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        receipt.submittedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(receipt.message, 'Exam finalized');
    });

    test('uses default message when message is missing', () {
      final receipt = SubmissionReceiptMapper.fromJson(const {});

      expect(receipt.submissionId, startsWith('sub-'));
      expect(receipt.message, AppStrings.submitted);
    });
  });
}
