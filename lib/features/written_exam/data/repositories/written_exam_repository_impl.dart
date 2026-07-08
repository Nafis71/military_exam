import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/config/deployment.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../domain/repositories/written_exam_repository.dart';

class WrittenExamRepositoryImpl implements WrittenExamRepository {
  WrittenExamRepositoryImpl(this._apiClient, this._storage);

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;
  final _uuid = const Uuid();

  static const _imagesKey = 'written_exam_images';

  @override
  Future<Result<WrittenAnswerImage>> addImage(String localPath) async {
    final imagesResult = await getImages();
    if (imagesResult is ErrorResult<List<WrittenAnswerImage>>) {
      return ErrorResult(imagesResult.failure);
    }

    final image = WrittenAnswerImage(
      localId: _uuid.v4(),
      localPath: localPath,
    );
    final updated = <WrittenAnswerImage>[...(imagesResult.dataOrNull ?? []), image];
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

    images[index] = WrittenAnswerImage(
      localId: localId,
      localPath: newLocalPath,
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
    images.removeWhere((img) => img.localId == localId);
    await _persistImages(images);
    return const Success(null);
  }

  @override
  Future<Result<UploadProgress>> uploadImage(String localId) async {
    final imagesResult = await getImages();
    if (imagesResult is ErrorResult<List<WrittenAnswerImage>>) {
      return ErrorResult(imagesResult.failure);
    }

    final images = imagesResult.dataOrNull ?? [];
    final index = images.indexWhere((img) => img.localId == localId);
    if (index < 0) {
      return const ErrorResult(ValidationFailure(AppStrings.imageNotFound));
    }

    final image = images[index];
    if (!File(image.localPath).existsSync()) {
      return const ErrorResult(UploadFailure(AppStrings.imageFileNotFound));
    }

    images[index] = image.copyWith(
      uploadStatus: ImageUploadStatus.uploading,
      uploadProgress: 0,
    );
    await _persistImages(images);

    if (Deployment.instance.isDemo) {
      images[index] = images[index].copyWith(
        remoteId: 'demo-local-$localId',
        uploadStatus: ImageUploadStatus.uploaded,
        uploadProgress: 1,
      );
      await _persistImages(images);
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
      await _persistImages(images);
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
    await _persistImages(images);
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
    try {
      final raw = await _storage.read(key: _imagesKey);
      if (raw == null) return const Success([]);
      final list = jsonDecode(raw) as List<dynamic>;
      return Success(
        list
            .map(
              (e) => WrittenAnswerImage(
                localId: e['local_id'] as String,
                localPath: e['local_path'] as String,
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

  Future<void> _persistImages(List<WrittenAnswerImage> images) async {
    final encoded = jsonEncode(
      images
          .map(
            (e) => {
              'local_id': e.localId,
              'local_path': e.localPath,
              'remote_id': e.remoteId,
              'upload_status': e.uploadStatus.name,
              'upload_progress': e.uploadProgress,
            },
          )
          .toList(),
    );
    await _storage.write(key: _imagesKey, value: encoded);
  }
}
