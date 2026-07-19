import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/constants/app_strings.dart';
import 'package:military_exam/core/errors/error_mapper.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/network/api_client.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/written_exam/data/repositories/written_exam_repository_impl.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('addImage rejects second image for same question', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(Dio(BaseOptions(baseUrl: 'http://localhost')), ErrorMapper());
    final repository = WrittenExamRepositoryImpl(apiClient, storage);

    final first = await repository.addImage('/tmp/a.jpg', 'q1');
    expect(first, isA<Success<dynamic>>());

    final second = await repository.addImage('/tmp/b.jpg', 'q1');
    expect(second, isA<ErrorResult<WrittenAnswerImage>>());
    switch (second) {
      case ErrorResult(:final failure):
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, AppStrings.writtenExamMaxOneImage);
      default:
        fail('Expected error result');
    }
  });
}
