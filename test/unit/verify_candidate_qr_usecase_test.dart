import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/constants/app_strings.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/identity_verification/data/repositories/identity_verification_repository_impl.dart';
import 'package:military_exam/features/identity_verification/domain/usecases/verify_candidate_qr_usecase.dart';

void main() {
  group('VerifyCandidateQrUseCase', () {
    late VerifyCandidateQrUseCase useCase;

    setUp(() {
      useCase = VerifyCandidateQrUseCase(
        IdentityVerificationRepositoryImpl(),
      );
    });

    test('fails for empty payload', () async {
      final result = await useCase('');
      expect(result.isFailure, isTrue);
      expect(
        result.failureOrNull?.message,
        AppStrings.identityVerificationFailed,
      );
    });

    test('fails for whitespace-only payload', () async {
      final result = await useCase('   ');
      expect(result.isFailure, isTrue);
    });

    test('succeeds for any non-empty payload', () async {
      final result = await useCase('hall-qr-token-123');
      expect(result, isA<Success<void>>());
    });
  });
}
