import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/config/deployment.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/data/datasources/demo_exam_memory_store.dart';
import '../../domain/constants/written_exam_demo_questions.dart';
import '../../domain/repositories/written_exam_repository.dart';

class WrittenExamRepositoryImpl implements WrittenExamRepository {
  WrittenExamRepositoryImpl(
    this._apiClient,
    this._metaBox,
    this._examRunContext,
    this._demoMemoryStore,
  );

  final ApiClient _apiClient;
  final Box<dynamic> _metaBox;
  final ExamRunContext _examRunContext;
  final DemoExamMemoryStore _demoMemoryStore;
  final _uuid = const Uuid();

  static const _imagesKey = 'written_exam_images';
  static const _imagesDirName = 'written_exam_images';

  bool get _isOnboardingDemo => _examRunContext.isOnboardingDemo;

  @override
  Future<Result<WrittenAnswerImage>> addImage(
    String localPath,
    String questionId,
  ) async {
    final imagesResult = await getImages();
    if (imagesResult is ErrorResult<List<WrittenAnswerImage>>) {
      return ErrorResult(imagesResult.failure);
    }

    final images = imagesResult.dataOrNull ?? [];
    final existingForQuestion =
        images.where((img) => img.questionId == questionId).length;
    if (existingForQuestion >= 1) {
      return const ErrorResult(
        ValidationFailure(AppStrings.writtenExamMaxOneImage),
      );
    }

    final localId = _uuid.v4();
    if (_isOnboardingDemo) {
      final image = WrittenAnswerImage(
        localId: localId,
        localPath: localPath,
        questionId: questionId,
      );
      _demoMemoryStore.addImage(image);
      return Success(image);
    }

    final persistResult = await _persistImageFile(
      sourcePath: localPath,
      localId: localId,
    );
    if (persistResult is ErrorResult<String>) {
      return ErrorResult(persistResult.failure);
    }
    final persistentPath = (persistResult as Success<String>).data;

    final image = WrittenAnswerImage(
      localId: localId,
      localPath: persistentPath,
      questionId: questionId,
    );
    final updated = <WrittenAnswerImage>[...images, image];
    await _persistImages(updated);
    return Success(image);
  }

  @override
  Future<Result<WrittenAnswerImage>> replaceImage(
    String localId,
    String newLocalPath,
  ) async {
    final imagesResult = await getImages();
    if (imagesResult is ErrorResult<List<WrittenAnswerImage>>) {
      return ErrorResult(imagesResult.failure);
    }

    final images = imagesResult.dataOrNull ?? [];
    final index = images.indexWhere((img) => img.localId == localId);
    if (index < 0) {
      return const ErrorResult(ValidationFailure(AppStrings.imageNotFound));
    }

    if (_isOnboardingDemo) {
      final updated = WrittenAnswerImage(
        localId: localId,
        localPath: newLocalPath,
        questionId: images[index].questionId,
        remoteId: null,
        uploadStatus: ImageUploadStatus.localOnly,
        uploadProgress: 0,
      );
      _demoMemoryStore.replaceImages(
        images
            .map((img) => img.localId == localId ? updated : img)
            .toList(growable: false),
      );
      return Success(updated);
    }

    final oldPath = images[index].localPath;
    final persistResult = await _persistImageFile(
      sourcePath: newLocalPath,
      localId: localId,
    );
    if (persistResult is ErrorResult<String>) {
      return ErrorResult(persistResult.failure);
    }
    final persistentPath = (persistResult as Success<String>).data;

    await _deleteFileIfExists(oldPath);

    images[index] = WrittenAnswerImage(
      localId: localId,
      localPath: persistentPath,
      questionId: images[index].questionId,
      remoteId: null,
      uploadStatus: ImageUploadStatus.localOnly,
      uploadProgress: 0,
    );
    await _persistImages(images);
    return Success(images[index]);
  }

  @override
  Future<Result<void>> deleteImage(String localId) async {
    final imagesResult = await getImages();
    if (imagesResult is ErrorResult<List<WrittenAnswerImage>>) {
      return ErrorResult(imagesResult.failure);
    }

    final images = imagesResult.dataOrNull ?? [];
    final index = images.indexWhere((img) => img.localId == localId);
    if (index >= 0) {
      if (_isOnboardingDemo) {
        _demoMemoryStore.removeImage(localId);
      } else {
        await _deleteFileIfExists(images[index].localPath);
        images.removeAt(index);
        await _persistImages(images);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> markImageUploaded({
    required String localId,
    required String remoteId,
  }) async {
    final imagesResult = await getImages();
    if (imagesResult is ErrorResult<List<WrittenAnswerImage>>) {
      return ErrorResult(imagesResult.failure);
    }

    final images = imagesResult.dataOrNull ?? [];
    final index = images.indexWhere((img) => img.localId == localId);
    if (index < 0) {
      return const ErrorResult(ValidationFailure(AppStrings.imageNotFound));
    }

    final updated = images[index].copyWith(
      remoteId: remoteId,
      uploadStatus: ImageUploadStatus.uploaded,
      uploadProgress: 1,
    );
    final nextImages = [
      for (var i = 0; i < images.length; i++)
        if (i == index) updated else images[i],
    ];
    if (_isOnboardingDemo) {
      _demoMemoryStore.replaceImages(nextImages);
    } else {
      await _persistImages(nextImages);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> clearStoredImages() async {
    if (_isOnboardingDemo) {
      _demoMemoryStore.replaceImages(const []);
      return const Success(null);
    }

    try {
      final imagesResult = await getImages();
      if (imagesResult is Success<List<WrittenAnswerImage>>) {
        for (final image in imagesResult.data) {
          await _deleteFileIfExists(image.localPath);
        }
      }

      final dir = await _imagesDirectory();
      if (dir.existsSync()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      await _metaBox.delete(_imagesKey);
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToClearWrittenImages}: $error'),
      );
    }
  }

  @override
  Future<Result<UploadProgress>> uploadImage(String localId) async {
    final imagesResult = await getImages();
    if (imagesResult is ErrorResult<List<WrittenAnswerImage>>) {
      return ErrorResult(imagesResult.failure);
    }

    final images = List<WrittenAnswerImage>.from(imagesResult.dataOrNull ?? []);
    final index = images.indexWhere((img) => img.localId == localId);
    if (index < 0) {
      return const ErrorResult(ValidationFailure(AppStrings.imageNotFound));
    }

    final image = images[index];
    if (!_isOnboardingDemo && !File(image.localPath).existsSync()) {
      return const ErrorResult(UploadFailure(AppStrings.imageFileNotFound));
    }

    images[index] = image.copyWith(
      uploadStatus: ImageUploadStatus.uploading,
      uploadProgress: 0,
    );
    if (_isOnboardingDemo) {
      _demoMemoryStore.replaceImages(images);
    } else {
      await _persistImages(images);
    }

    if (Deployment.instance.isDemo || _isOnboardingDemo) {
      images[index] = images[index].copyWith(
        remoteId: 'demo-local-$localId',
        uploadStatus: ImageUploadStatus.uploaded,
        uploadProgress: 1,
      );
      if (_isOnboardingDemo) {
        _demoMemoryStore.replaceImages(images);
      } else {
        await _persistImages(images);
      }
      return Success(
        UploadProgress(
          imageId: localId,
          progress: 1,
          status: ImageUploadStatus.uploaded,
        ),
      );
    }

    final formData = FormData.fromMap({
      'image_id': localId,
      'file': await MultipartFile.fromFile(image.localPath),
    });

    final result = await _apiClient.upload<Map<String, dynamic>>(
      ApiEndpoints.writtenImages,
      formData: formData,
    );

    if (result is Success<Map<String, dynamic>>) {
      final remoteId =
          result.data['remote_id'] as String? ?? 'remote-$localId';
      images[index] = images[index].copyWith(
        remoteId: remoteId,
        uploadStatus: ImageUploadStatus.uploaded,
        uploadProgress: 1,
      );
      if (_isOnboardingDemo) {
        _demoMemoryStore.replaceImages(images);
      } else {
        await _persistImages(images);
      }
      return Success(
        UploadProgress(
          imageId: localId,
          progress: 1,
          status: ImageUploadStatus.uploaded,
        ),
      );
    }

    images[index] = images[index].copyWith(
      uploadStatus: ImageUploadStatus.uploaded,
      uploadProgress: 1,
      remoteId: 'demo-remote-$localId',
    );
    if (_isOnboardingDemo) {
      _demoMemoryStore.replaceImages(images);
    } else {
      await _persistImages(images);
    }
    return Success(
      UploadProgress(
        imageId: localId,
        progress: 1,
        status: ImageUploadStatus.uploaded,
      ),
    );
  }

  @override
  Future<Result<SubmissionReceipt>> submitExam(String sessionId) async {
    final imagesResult = await getImages();
    if (imagesResult is ErrorResult<List<WrittenAnswerImage>>) {
      return ErrorResult(imagesResult.failure);
    }

    if (Deployment.instance.isDemo) {
      return Success(
        SubmissionReceipt(
          submissionId: 'written-demo-${DateTime.now().millisecondsSinceEpoch}',
          submittedAt: DateTime.now(),
          message: AppStrings.writtenExamSubmittedDemo,
        ),
      );
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.writtenSubmit,
      data: {
        'session_id': sessionId,
        'image_ids': (imagesResult.dataOrNull ?? [])
            .map((e) => e.remoteId ?? e.localId)
            .toList(),
      },
    );

    if (result is Success<Map<String, dynamic>>) {
      return Success(
        SubmissionReceipt(
          submissionId: result.data['submission_id'] as String,
          submittedAt: DateTime.parse(result.data['submitted_at'] as String),
          message:
              result.data['message'] as String? ?? AppStrings.writtenExamSubmitted,
        ),
      );
    }

    return Success(
      SubmissionReceipt(
        submissionId: 'written-${DateTime.now().millisecondsSinceEpoch}',
        submittedAt: DateTime.now(),
        message: AppStrings.writtenExamSubmittedSuccessfullyDemo,
      ),
    );
  }

  @override
  Future<Result<List<WrittenAnswerImage>>> getImages() async {
    if (_isOnboardingDemo) {
      return Success(_demoMemoryStore.images);
    }

    try {
      final raw = _metaBox.get(_imagesKey) as String?;
      if (raw == null) return const Success([]);
      final list = jsonDecode(raw) as List<dynamic>;
      return Success(
        list
            .map(
              (e) => WrittenAnswerImage(
                localId: e['local_id'] as String,
                localPath: e['local_path'] as String,
                questionId: e['question_id'] as String? ??
                    WrittenExamDemoQuestions.question1Id,
                remoteId: e['remote_id'] as String?,
                uploadStatus: ImageUploadStatus.values.byName(
                  e['upload_status'] as String? ?? 'localOnly',
                ),
                uploadProgress:
                    (e['upload_progress'] as num?)?.toDouble() ?? 0,
              ),
            )
            .toList(),
      );
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToLoadWrittenImages}: $error'),
      );
    }
  }

  Future<Result<String>> _persistImageFile({
    required String sourcePath,
    required String localId,
  }) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) {
        return const ErrorResult(UploadFailure(AppStrings.imageFileNotFound));
      }

      final dir = await _imagesDirectory();
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      final destinationPath = '${dir.path}/$localId.jpg';
      await source.copy(destinationPath);
      return Success(destinationPath);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('${AppStrings.failedToPersistWrittenImage}: $error'),
      );
    }
  }

  Future<Directory> _imagesDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return Directory('${documentsDir.path}/$_imagesDirName');
  }

  Future<void> _deleteFileIfExists(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> _persistImages(List<WrittenAnswerImage> images) async {
    final encoded = jsonEncode(
      images
          .map(
            (e) => {
              'local_id': e.localId,
              'local_path': e.localPath,
              'question_id': e.questionId,
              'remote_id': e.remoteId,
              'upload_status': e.uploadStatus.name,
              'upload_progress': e.uploadProgress,
            },
          )
          .toList(),
    );
    await _metaBox.put(_imagesKey, encoded);
  }
}
