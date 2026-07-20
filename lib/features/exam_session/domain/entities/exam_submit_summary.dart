import 'package:equatable/equatable.dart';

class ExamSubmitSummary extends Equatable {
  const ExamSubmitSummary({
    required this.examName,
    required this.batchName,
    required this.totalDurationMinutes,
    required this.elapsedSeconds,
    required this.totalQuestions,
    required this.answeredQuestions,
  });

  final String examName;
  final String batchName;
  final int totalDurationMinutes;
  final int elapsedSeconds;
  final int totalQuestions;
  final int answeredQuestions;

  @override
  List<Object?> get props => [
        examName,
        batchName,
        totalDurationMinutes,
        elapsedSeconds,
        totalQuestions,
        answeredQuestions,
      ];
}
