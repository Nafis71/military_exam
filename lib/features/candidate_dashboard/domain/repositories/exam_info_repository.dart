import '../../../../core/utils/result.dart';
import '../../domain/entities/exam_info.dart';

abstract class ExamInfoRepository {
  Future<Result<ExamInfo>> getExamInfo();
}
