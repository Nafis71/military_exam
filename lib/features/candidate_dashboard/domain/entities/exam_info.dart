import 'package:equatable/equatable.dart';

class ExamInfo extends Equatable {
  const ExamInfo({
    required this.title,
    required this.date,
    required this.venue,
    required this.status,
  });

  final String title;
  final String date;
  final String venue;
  final String status;

  @override
  List<Object?> get props => [title, date, venue, status];
}
