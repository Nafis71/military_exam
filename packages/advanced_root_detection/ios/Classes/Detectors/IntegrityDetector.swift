import Foundation

/// Detects iOS app integrity violations: bundle ID, provisioning, code signing, install source.
///
/// Reference: OWASP MASTG MSTG-RESILIENCE-3
/// https://mas.owasp.org/MASTG/tests/ios/MASVS-RESILIENCE/MASTG-TEST-0037/
class IntegrityDetector {
    static let shared = IntegrityDetector()
    private init() {}

    func detect(config: DetectionConfig) -> [ThreatResult] {
        var threats: [ThreatResult] = []

        // 1. Bundle ID verification
        if !config.bundleIds.isEmpty {
            let actualBundle = Bundle.main.bundleIdentifier ?? ""
            if !config.bundleIds.contains(actualBundle) {
                threats.append(ThreatResult(
                    category: "integrityViolation",
                    description: "Bundle ID mismatch — possible repackaging",
                    severity: "critical",
                    details: ["expected": config.bundleIds.joined(separator: ","), "actual": actualBundle]
                ))
            }
        }

        // 2. Provisioning profile presence
        if !hasProvisioningProfile() {
            threats.append(ThreatResult(
                category: "integrityViolation",
                description: "No embedded provisioning profile found — possible sideload or tampering",
                severity: "high"
            ))
        }

        // 3. Install source detection
        if let sourceIssue = detectInstallSource() {
            threats.append(sourceIssue)
        }

        return threats
    }

    private func hasProvisioningProfile() -> Bool {
        guard let profilePath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
            return false
        }
        return FileManager.default.fileExists(atPath: profilePath)
    }

    private func detectInstallSource() -> ThreatResult? {
        // App Store / TestFlight apps have a receipt at a known path
        let appStoreReceiptPath = Bundle.main.appStoreReceiptURL?.path ?? ""

        if appStoreReceiptPath.contains("sandboxReceipt") {
            // TestFlight — acceptable for most apps
            return nil
        }

        if appStoreReceiptPath.isEmpty ||
           (!FileManager.default.fileExists(atPath: appStoreReceiptPath) && !hasProvisioningProfile()) {
            return ThreatResult(
                category: "untrustedSource",
                description: "App may have been sideloaded — no App Store receipt and no provisioning profile",
                severity: "medium"
            )
        }

        return nil
    }
}
