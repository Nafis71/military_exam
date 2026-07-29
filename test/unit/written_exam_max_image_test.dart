import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:military_exam/core/constants/app_strings.dart';
import 'package:military_exam/core/errors/error_mapper.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/network/api_client.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/written_exam/data/repositories/written_exam_repository_impl.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/demo_exam_test_support.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      '${Directory.systemTemp.path}/written_exam_test_docs';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveTestDir;
  late Box<dynamic> metaBox;

  setUp(() async {
    PathProviderPlatform.instance = _FakePathProvider();
    hiveTestDir = Directory(
      '${Directory.systemTemp.path}/military_exam_hive_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    await hiveTestDir.create(recursive: true);
    Hive.init(hiveTestDir.path);
    metaBox = await Hive.openBox<dynamic>('written_exam_meta_test');
  });

  tearDown(() async {
    await metaBox.close();
    await Hive.close();
    if (hiveTestDir.existsSync()) {
      await hiveTestDir.delete(recursive: true);
    }
  });

  test('addImage rejects second image for same question', () async {
    final apiClient = ApiClient(Dio(BaseOptions(baseUrl: 'http://localhost')), ErrorMapper());
    final deps = createLinkedDemoExamDependencies();
    final repository = WrittenExamRepositoryImpl(
      apiClient,
      metaBox,
      deps.examRunContext,
      deps.demoMemoryStore,
    );

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

  test('markImageUploaded updates demo image without crash', () async {
    final apiClient = ApiClient(
      Dio(BaseOptions(baseUrl: 'http://localhost')),
      ErrorMapper(),
    );
    final deps = createLinkedDemoExamDependencies();
    deps.examRunContext.setOnboardingDemo();
    final repository = WrittenExamRepositoryImpl(
      apiClient,
      metaBox,
      deps.examRunContext,
      deps.demoMemoryStore,
    );

    final imageFile = File(
      '${Directory.systemTemp.path}/written_mark_uploaded_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await imageFile.writeAsBytes([1, 2, 3]);

    final addResult = await repository.addImage(imageFile.path, 'q1');
    expect(addResult, isA<Success<WrittenAnswerImage>>());
    final localId = (addResult as Success<WrittenAnswerImage>).data.localId;

    final markResult = await repository.markImageUploaded(
      localId: localId,
      remoteId: 'remote-demo-1',
    );

    expect(markResult, isA<Success<void>>());
    final storedImages = deps.demoMemoryStore.images;
    expect(storedImages, hasLength(1));
    expect(storedImages.first.remoteId, 'remote-demo-1');
    expect(storedImages.first.uploadStatus, ImageUploadStatus.uploaded);
    expect(storedImages.first.uploadProgress, 1);

    await repository.clearStoredImages();
    await imageFile.delete();
  });
}
