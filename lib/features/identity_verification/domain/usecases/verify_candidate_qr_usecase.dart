import '../../../../core/utils/result.dart';
import '../repositories/identity_verification_repository.dart';

class VerifyCandidateQrUseCase {
  VerifyCandidateQrUseCase(this._repository);

  final IdentityVerificationRepository _repository;

  Future<Result<void>> call(String rawPayload) {
    return _repository.verifyQr(rawPayload.trim());
  }
}
