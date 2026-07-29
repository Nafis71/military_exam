import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/identity_verification_repository.dart';

/// Mock implementation — accepts any non-empty QR payload until API is wired.
class IdentityVerificationRepositoryImpl implements IdentityVerificationRepository {
  @override
  Future<Result<void>> verifyQr(String payload) async {
    if (payload.trim().isEmpty) {
      return const ErrorResult(
        ValidationFailure(AppStrings.identityVerificationFailed),
      );
    }

    // TODO: call identity verification API
    return const Success(null);
  }
}
