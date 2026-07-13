import '../../../../shared/domain/entities/exam_entities.dart';

abstract final class WrittenExamDemoQuestions {
  static const String question1Id = 'written-q1';
  static const String question2Id = 'written-q2';

  static const List<WrittenQuestion> all = [
    WrittenQuestion(
      id: question1Id,
      index: 1,
      text: 'তোমার জীবনের লক্ষ্য সম্পর্কে ১০টি বাক্য লেখ।',
    ),
    WrittenQuestion(
      id: question2Id,
      index: 2,
      text: 'তোমার দেশ সম্পর্কে ৫টি বাক্য লেখ।',
    ),
  ];
}
