import Foundation

/// Detects simulator and analysis environment indicators on iOS.
///
/// Reference: OWASP MASTG MSTG-RESILIENCE-5
/// https://mas.owasp.org/MASTG/tests/ios/MASVS-RESILIENCE/MASTG-TEST-0039/
class EnvironmentDetector {
    static let shared = EnvironmentDetector()
    private init() {}

    func detect() -> [ThreatResult] {
        var threats: [ThreatResult] = []

        // 1. Simulator detection
        if isSimulator() {
            threats.append(ThreatResult(
                category: "analysisEnvironment",
                description: "Running inside iOS Simulator",
                severity: "high"
            ))
        }

        return threats
    }

    private func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        // Additional runtime checks for edge cases (e.g. re-signed simulator builds)
        let simulatorEnvVars = [
            "SIMULATOR_DEVICE_NAME",
            "SIMULATOR_MODEL_IDENTIFIER",
            "XPC_SIMULATOR_LAUNCHD_NAME",
        ]
        for envVar in simulatorEnvVars {
            if ProcessInfo.processInfo.environment[envVar] != nil {
                return true
            }
        }

        // Hardware model: simulator reports "x86_64" or "arm64" (same as Mac on Apple Silicon)
        var sysInfo = utsname()
        uname(&sysInfo)
        let machine = withUnsafeBytes(of: &sysInfo.machine) { bytes -> String in
            let chars = bytes.bindMemory(to: CChar.self)
            return String(cString: chars.baseAddress!)
        }
        if machine == "x86_64" || machine == "arm64" {
            // Could be simulator on Apple Silicon; cross-check with other indicators
            if ProcessInfo.processInfo.environment["HOME"]?.contains("CoreSimulator") == true {
                return true
            }
        }
        return false
        #endif
    }
}
