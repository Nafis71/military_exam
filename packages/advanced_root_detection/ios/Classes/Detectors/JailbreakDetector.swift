import Foundation
import UIKit

/// Detects jailbreak indicators on iOS.
///
/// Covers classic paths, modern jailbreaks (Dopamine, palera1n, rootless),
/// URL scheme probing, sandbox escape, and writability tests.
///
/// Reference: OWASP MASTG MSTG-RESILIENCE-1
/// https://mas.owasp.org/MASTG/tests/ios/MASVS-RESILIENCE/MASTG-TEST-0035/
class JailbreakDetector {
    static let shared = JailbreakDetector()
    private init() {}

    // Classic jailbreak paths
    private let classicPaths = [
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/private/var/lib/apt/",
        "/usr/bin/ssh",
        "/usr/libexec/ssh-keysign",
        "/private/var/lib/dpkg/info/cydia.list",
    ]

    // Modern rootless / palera1n / Dopamine paths
    private let modernPaths = [
        "/var/jb/",
        "/var/jb/usr/bin/bash",
        "/var/jb/etc/apt",
        "/var/jb/.installed_dopamine",
        "/var/jb/.installed_palera1n",
        "/private/preboot/jb",
        "/cores/binpack",
        "/cores/binpack/Applications/palera1nLoader.app",
        "/usr/lib/libhooker.dylib",
        "/usr/lib/libsubstitute.dylib",
        "/usr/lib/substrate",
    ]

    // Jailbreak app URL schemes
    private let jailbreakURLSchemes = [
        "cydia://",
        "sileo://",
        "zbra://",
        "filza://",
        "undecimus://",
        "activator://",
    ]

    func detect(config: DetectionConfig) -> [ThreatResult] {
        if config.skipJailbreakOnSimulator && SimulatorEnvironment.isSimulator() {
            return []
        }

        var threats: [ThreatResult] = []

        // 1. Classic paths
        if let path = classicPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            threats.append(ThreatResult(
                category: "privilegedAccess",
                description: "Jailbreak path found: \(path)",
                severity: "critical",
                details: ["path": path]
            ))
        }

        // 2. Modern rootless paths
        if let path = modernPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            threats.append(ThreatResult(
                category: "privilegedAccess",
                description: "Modern jailbreak artifact found: \(path)",
                severity: "critical",
                details: ["path": path]
            ))
        }

        // 3. URL scheme probing
        if let scheme = jailbreakURLSchemes.first(where: { canOpenURL($0) }) {
            threats.append(ThreatResult(
                category: "privilegedAccess",
                description: "Jailbreak URL scheme responds: \(scheme)",
                severity: "critical",
                details: ["scheme": scheme]
            ))
        }

        // 4. Sandbox escape: jailbreak injection env vars present at process launch.
        // Cydia Substrate, Substitute, and libhooker set DYLD_INSERT_LIBRARIES /
        // _MSSafeMode / SUBSTRATE_ACTIVE before main() runs. These are only ever
        // present when a tweak-injection framework has breached the app sandbox.
        // (Replaces fork()-based check which is rejected by App Store binary analysis.)
        if hasSandboxEscapeEnvVars() {
            threats.append(ThreatResult(
                category: "privilegedAccess",
                description: "Sandbox escape detected: jailbreak injection environment variable present",
                severity: "critical"
            ))
        }

        // 5. Writability test on /private/
        if isPrivateWritable() {
            threats.append(ThreatResult(
                category: "privilegedAccess",
                description: "/private/ directory is writable — sandbox escape detected",
                severity: "critical"
            ))
        }

        // 6. Symbolic link check on /Applications
        if isApplicationsSymlink() {
            threats.append(ThreatResult(
                category: "privilegedAccess",
                description: "/Applications is a symbolic link — common jailbreak indicator",
                severity: "high"
            ))
        }

        return threats
    }

    private func canOpenURL(_ scheme: String) -> Bool {
        guard let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private func hasSandboxEscapeEnvVars() -> Bool {
        // Cydia Substrate sets _MSSafeMode; Substitute / libhooker set DYLD_INSERT_LIBRARIES;
        // some jailbreak loaders set SUBSTRATE_ACTIVE. Any of these present = sandbox breached.
        let indicators = ["DYLD_INSERT_LIBRARIES", "_MSSafeMode", "SUBSTRATE_ACTIVE"]
        let env = ProcessInfo.processInfo.environment
        return indicators.contains { env[$0] != nil }
    }

    private func isPrivateWritable() -> Bool {
        let testPath = "/private/jailbreak_test_\(Int.random(in: 100000...999999)).txt"
        let result = FileManager.default.createFile(atPath: testPath, contents: Data("test".utf8))
        if result {
            try? FileManager.default.removeItem(atPath: testPath)
        }
        return result
    }

    private func isApplicationsSymlink() -> Bool {
        let attributes = try? FileManager.default.attributesOfItem(atPath: "/Applications")
        return attributes?[.type] as? FileAttributeType == .typeSymbolicLink
    }
}
