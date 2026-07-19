import Foundation

/// Shared iOS simulator detection used by environment and jailbreak detectors.
enum SimulatorEnvironment {
    static func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
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

        var sysInfo = utsname()
        uname(&sysInfo)
        let machine = withUnsafeBytes(of: &sysInfo.machine) { bytes -> String in
            let chars = bytes.bindMemory(to: CChar.self)
            return String(cString: chars.baseAddress!)
        }
        if machine == "x86_64" || machine == "arm64" {
            if ProcessInfo.processInfo.environment["HOME"]?.contains("CoreSimulator") == true {
                return true
            }
        }
        return false
        #endif
    }
}

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
        SimulatorEnvironment.isSimulator()
    }
}
