import '../../../../shared/domain/entities/exam_entities.dart';
import '../../domain/entities/candidate.dart';

class CandidateModel extends Candidate {
  const CandidateModel({
    required super.id,
    required super.fullName,
    required super.district,
    required super.rollNumber,
    required super.status,
  });

  factory CandidateModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CandidateModel(
      id: data['id'] as String,
      fullName: data['full_name'] as String,
      district: data['district'] as String? ?? '',
      rollNumber: data['roll_number'] as String,
      status: data['status'] as String,
    );
  }

  AuthSession toAuthSession() {
    return AuthSession(
      token: '',
      sessionId: id,
      examinee: Examinee(id: id, name: fullName),
      expiresAt: DateTime.now().add(const Duration(hours: 4)),
    );
  }
}
