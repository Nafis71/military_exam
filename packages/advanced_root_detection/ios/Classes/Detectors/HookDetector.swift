import Foundation
import MachO

/// Detects hooking frameworks on iOS: Frida, Cycript, Substrate, libhooker, Substitute.
///
/// Reference: OWASP MASTG MSTG-RESILIENCE-4
/// https://mas.owasp.org/MASTG/tests/ios/MASVS-RESILIENCE/MASTG-TEST-0038/
class HookDetector {
    static let shared = HookDetector()
    private init() {}

    private let hookingLibraries = [
        "FridaGadget",
        "frida",
        "cynject",
        "libcycript",
        "MobileSubstrate",
        "SubstrateLoader",
        "libsubstrate",
        "libhooker",
        "libsubstitute",
        "SSLKillSwitch",
        "SSLKillSwitch2",
        "TweakInject",
    ]

    func detect() -> [ThreatResult] {
        var threats: [ThreatResult] = []

        // 1. Scan loaded dylibs via _dyld_get_image_name
        if let lib = findHookingDylib() {
            threats.append(ThreatResult(
                category: "runtimeManipulation",
                description: "Hooking library loaded: \(lib)",
                severity: "critical",
                details: ["library": lib]
            ))
        }

        // 2. DYLD_INSERT_LIBRARIES environment variable
        if let inserted = ProcessInfo.processInfo.environment["DYLD_INSERT_LIBRARIES"],
           !inserted.isEmpty {
            threats.append(ThreatResult(
                category: "runtimeManipulation",
                description: "DYLD_INSERT_LIBRARIES set: \(inserted)",
                severity: "critical",
                details: ["value": inserted]
            ))
        }

        // 3. Cycript / cynject
        if FileManager.default.fileExists(atPath: "/usr/lib/libcycript.dylib") ||
           FileManager.default.fileExists(atPath: "/var/jb/usr/lib/libcycript.dylib") {
            threats.append(ThreatResult(
                category: "runtimeManipulation",
                description: "Cycript library found on disk",
                severity: "critical"
            ))
        }

        return threats
    }

    private func findHookingDylib() -> String? {
        let count = _dyld_image_count()
        for i in 0..<count {
            guard let name = _dyld_get_image_name(i) else { continue }
            let imageName = String(cString: name)
            for lib in hookingLibraries {
                if imageName.localizedCaseInsensitiveContains(lib) {
                    return imageName
                }
            }
        }
        return nil
    }
}
