import '../../../../core/utils/result.dart';

abstract class IdentityVerificationRepository {
  Future<Result<void>> verifyQr(String payload);
}
