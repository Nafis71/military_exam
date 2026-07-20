import 'dart:io';

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
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      '${Directory.systemTemp.path}/written_exam_test_docs';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = _FakePathProvider();
  });

  test('addImage rejects second image for same question', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(Dio(BaseOptions(baseUrl: 'http://localhost')), ErrorMapper());
    final repository = WrittenExamRepositoryImpl(apiClient, storage);

    final firstFile = File(
      '${Directory.systemTemp.path}/written_max_image_a_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final secondFile = File(
      '${Directory.systemTemp.path}/written_max_image_b_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await firstFile.writeAsBytes([1, 2, 3]);
    await secondFile.writeAsBytes([4, 5, 6]);

    final first = await repository.addImage(firstFile.path, 'q1');
    expect(first, isA<Success<dynamic>>());

    final second = await repository.addImage(secondFile.path, 'q1');
    expect(second, isA<ErrorResult<WrittenAnswerImage>>());
    switch (second) {
      case ErrorResult(:final failure):
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, AppStrings.writtenExamMaxOneImage);
      default:
        fail('Expected error result');
    }

    await repository.clearStoredImages();
    await firstFile.delete();
    await secondFile.delete();
  });
}
