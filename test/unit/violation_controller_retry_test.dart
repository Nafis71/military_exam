import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:military_exam/core/config/deployment.dart';
import 'package:military_exam/core/constants/app_strings.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/logging/app_logger.dart';
import 'package:military_exam/core/services/exam_vpn_lockdown_service.dart';
import 'package:military_exam/features/security_gate/domain/usecases/stop_exam_vpn_lockdown_usecase.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/core/services/app_lifecycle_service.dart';
import 'package:military_exam/features/exam_session/domain/entities/cached_exam_recovery_result.dart';
import 'package:military_exam/features/exam_session/domain/repositories/exam_repository.dart';
import 'package:military_exam/features/exam_session/domain/usecases/clear_exam_local_data_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/finalize_exam_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/submit_exam_with_pending_uploads_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/upload_pending_written_images_usecase.dart';
import 'package:military_exam/features/security_gate/domain/repositories/security_repository.dart';
import 'package:military_exam/features/security_gate/domain/usecases/check_connectivity_usecase.dart';
import 'package:military_exam/features/security_gate/domain/usecases/observe_connectivity_usecase.dart';
import 'package:military_exam/features/violation/presentation/models/violation_screen_args.dart';
import 'package:military_exam/features/violation/presentation/controllers/violation_controller.dart';
import 'package:military_exam/features/written_exam/domain/repositories/written_exam_repository.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  setUpAll(() {
    Deployment.init(demo: true);
  });

  late _FakeExamRepository examRepo;
  late _FakeWrittenExamRepository writtenRepo;
  late _FakeSecurityRepository securityRepository;
  late StreamController<ConnectivityStatus> connectivityController;
  late ViolationController controller;

  SubmitExamWithPendingUploadsUseCase buildSubmitUseCase() {
    final uploadUseCase = UploadPendingWrittenImagesUseCase(
      examRepo,
      writtenRepo,
    );
    return SubmitExamWithPendingUploadsUseCase(
      examRepo,
      uploadUseCase,
      FinalizeExamUseCase(examRepo),
      ClearExamLocalDataUseCase(examRepo, writtenRepo),
    );
  }

  setUp(() {
    examRepo = _FakeExamRepository();
    writtenRepo = _FakeWrittenExamRepository();
    securityRepository = _FakeSecurityRepository();
    connectivityController = StreamController<ConnectivityStatus>.broadcast();
    securityRepository.connectivityStream = connectivityController.stream;

    Get.testMode = true;

    controller = ViolationController(
      buildSubmitUseCase(),
      CheckConnectivityUseCase(securityRepository),
      ObserveConnectivityUseCase(securityRepository),
      StopExamVpnLockdownUseCase(_FakeVpnLockdownService()),
      _FakeLifecycleService(),
      AppLogger(),
      initialArgs: ViolationScreenArgs(
        violation: SecurityViolation(
          type: ViolationType.screenshotTaken,
          occurredAt: DateTime(2026, 7, 20, 12),
          phase: ExamPhase.written,
          sessionId: 'session-1',
          platform: 'ios',
        ),
        submissionPending: true,
      ),
    );
    controller.onInit();
  });

  tearDown(() async {
    controller.onClose();
    await connectivityController.close();
  });

  test('ViolationController retries submit when connectivity returns online',
      () async {
    securityRepository.nextConnectivityStatus =
        const ConnectivityStatus(isOnline: true);

    connectivityController.add(const ConnectivityStatus(isOnline: true));
    await Future<void>.delayed(Duration.zero);

    expect(examRepo.finalizeCalls, 1);
    expect(controller.answersSubmitted.value, isTrue);
    expect(controller.submissionPending.value, isFalse);
  });

  test('ViolationController keeps pending state on network retry failure',
      () async {
    examRepo.shouldFailFinalize = true;
    securityRepository.nextConnectivityStatus =
        const ConnectivityStatus(isOnline: true);

    connectivityController.add(const ConnectivityStatus(isOnline: true));
    await Future<void>.delayed(Duration.zero);

    expect(examRepo.finalizeCalls, 0);
    expect(controller.answersSubmitted.value, isFalse);
    expect(controller.submissionPending.value, isTrue);
    expect(controller.stopAutoRetry.value, isFalse);
  });

  test('ViolationController alertMessage shows pending copy while waiting', () {
    expect(
      controller.alertMessage,
      AppStrings.violationSubmissionPendingMessage,
    );
  });
}

class _FakeExamRepository implements ExamRepository {
  int finalizeCalls = 0;
  bool shouldFailFinalize = false;

  @override
  Future<Result<CurrentExam>> refreshCurrentExam() async {
    if (shouldFailFinalize) {
      return const ErrorResult(NetworkFailure('offline'));
    }
    return Success(
        CurrentExam(
          examId: 'exam-1',
          examName: 'Exam',
          batchName: 'Batch',
          batchStatus: 'active',
          batchId: 'batch-1',
          totalQuestions: 1,
          durationMinutes: 60,
          window: const ExamWindow(
            startTime: null,
            examEndTime: null,
            submitEndTime: null,
            bufferTimeMinutes: 0,
            canAccessQuestions: true,
            canSubmit: true,
            remainingExamMinutes: 60,
            remainingSubmitMinutes: 60,
          ),
          questions: const [],
        ),
      );
  }

  @override
  Future<Result<SubmissionReceipt>> finalizeExam(CurrentExam? currentExam) async {
    if (shouldFailFinalize) {
      return const ErrorResult(NetworkFailure('offline'));
    }
    finalizeCalls += 1;
    return Success(
      SubmissionReceipt(
        submissionId: 'sub-1',
        submittedAt: DateTime(2026, 7, 20, 12),
        message: 'ok',
      ),
    );
  }

  @override
  Future<Result<void>> clearLocalExamData() async => const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeWrittenExamRepository implements WrittenExamRepository {
  @override
  Future<Result<List<WrittenAnswerImage>>> getImages() async =>
      const Success([]);

  @override
  Future<Result<void>> clearStoredImages() async => const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSecurityRepository implements SecurityRepository {
  Stream<ConnectivityStatus>? connectivityStream;
  ConnectivityStatus? nextConnectivityStatus =
      const ConnectivityStatus(isOnline: false);

  @override
  Future<Result<ConnectivityStatus>> checkConnectivity() async =>
      Success(nextConnectivityStatus!);

  @override
  Stream<ConnectivityStatus> observeConnectivity() =>
      connectivityStream ?? const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeLifecycleService extends AppLifecycleService {
  @override
  Stream<AppLifecycleState> get lifecycleStream => const Stream.empty();
}

class _FakeVpnLockdownService extends ExamVpnLockdownService {
  _FakeVpnLockdownService() : super(AppLogger());

  @override
  Future<void> stopLockdown() async {}
}
