import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:military_exam/core/config/build_mode.dart';
import 'package:military_exam/core/config/deployment.dart';
import 'package:military_exam/core/constants/app_strings.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/logging/app_logger.dart';
import 'package:military_exam/core/network/api_client.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_remote_datasource.dart';
import 'package:military_exam/features/exam_session/data/models/current_exam_model.dart';

import '../helpers/demo_exam_test_support.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late ExamRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(const ErrorResult<Map<String, dynamic>>(
      UnexpectedFailure('fallback'),
    ));
  });

  setUp(() {
    Deployment.init(mode: BuildMode.production);
    apiClient = _MockApiClient();
    dataSource = ExamRemoteDataSourceImpl(
      apiClient,
      AppLogger(),
      createExamRunContext(),
    );
  });

  group('ExamRemoteDataSourceImpl.fetchCurrentExam', () {
    test('returns ErrorResult when API fails in real mode', () async {
      when(() => apiClient.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => const ErrorResult<Map<String, dynamic>>(
          NetworkFailure('offline'),
        ),
      );

      final result = await dataSource.fetchCurrentExam();

      expect(result, isA<ErrorResult<CurrentExamModel>>());
      expect(
        (result as ErrorResult<CurrentExamModel>).failure,
        isA<NetworkFailure>(),
      );
    });

    test('returns ErrorResult when API payload shape is invalid', () async {
      when(() => apiClient.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => const Success<Map<String, dynamic>>({'data': 'bad-shape'}),
      );

      final result = await dataSource.fetchCurrentExam();

      expect(result, isA<ErrorResult<CurrentExamModel>>());
      expect(
        (result as ErrorResult<CurrentExamModel>).failure.message,
        AppStrings.networkRequestFailed,
      );
    });

    test('does not return demo exam when API fails in real mode', () async {
      when(() => apiClient.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => const ErrorResult<Map<String, dynamic>>(
          UnexpectedFailure('server error'),
        ),
      );

      final result = await dataSource.fetchCurrentExam();

      expect(result, isA<ErrorResult<CurrentExamModel>>());
      expect(result, isNot(isA<Success<CurrentExamModel>>()));
    });
  });
}
