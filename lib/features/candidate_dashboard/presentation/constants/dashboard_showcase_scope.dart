abstract final class DashboardShowcaseScope {
  static const scope = 'dashboard';

  /// Incremented each time a [CandidateDashboardShowcaseHost] registers.
  static int registrationGeneration = 0;

  /// Generation of the host that currently owns the registered scope.
  static int activeRegistrationGeneration = 0;

  static bool get isScopeReady =>
      registrationGeneration > 0 &&
      activeRegistrationGeneration == registrationGeneration;
}
