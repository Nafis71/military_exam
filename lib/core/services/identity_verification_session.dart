/// In-memory flag for QR identity verification within the real exam flow.
/// Cleared when returning to the dashboard; replaced by API session later.
class IdentityVerificationSession {
  bool _isVerified = false;

  bool get isVerified => _isVerified;

  void markVerified() => _isVerified = true;

  void clear() => _isVerified = false;
}
