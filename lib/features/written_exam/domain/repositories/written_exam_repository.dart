import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

abstract class WrittenExamRepository {
  Future<Result<WrittenAnswerImage>> addImage(
    String localPath,
    String questionId,
  );

  Future<Result<WrittenAnswerImage>> replaceImage(
    String localId,
    String newLocalPath,
  );

  Future<Result<void>> deleteImage(String localId);

  Future<Result<UploadProgress>> uploadImage(String localId);

  Future<Result<SubmissionReceipt>> submitExam(String sessionId);

  Future<Result<List<WrittenAnswerImage>>> getImages();
}
