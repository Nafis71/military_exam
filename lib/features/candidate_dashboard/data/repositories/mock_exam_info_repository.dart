import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/exam_info.dart';
import '../../domain/repositories/exam_info_repository.dart';

class MockExamInfoRepository implements ExamInfoRepository {
  @override
  Future<Result<ExamInfo>> getExamInfo() async {
    return const Success(
      ExamInfo(
        title: AppStrings.mockExamTitle,
        date: AppStrings.mockExamDate,
        venue: AppStrings.mockExamVenue,
        status: AppStrings.mockExamStatus,
      ),
    );
  }
}
