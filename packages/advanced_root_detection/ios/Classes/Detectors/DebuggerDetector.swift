import Foundation
import Darwin

/// Detects attached debuggers on iOS.
///
/// Reference: OWASP MASTG MSTG-RESILIENCE-2
/// https://mas.owasp.org/MASTG/tests/ios/MASVS-RESILIENCE/MASTG-TEST-0036/
class DebuggerDetector {
    static let shared = DebuggerDetector()
    private init() {}

    func detect() -> [ThreatResult] {
        var threats: [ThreatResult] = []

        // 1. sysctl P_TRACED check
        if isBeingTracedSysctl() {
            threats.append(ThreatResult(
                category: "debuggerAttached",
                description: "Debugger detected via sysctl KERN_PROC P_TRACED flag",
                severity: "critical"
            ))
        }

        // 2. ptrace PT_DENY_ATTACH (only effective in release builds outside simulator)
        #if !targetEnvironment(simulator) && !DEBUG
        applyPtraceDenyAttach()
        #endif

        return threats
    }

    /// Checks the P_TRACED flag via sysctl.
    private func isBeingTracedSysctl() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let ret = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        guard ret == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    /// Applies ptrace(PT_DENY_ATTACH) to prevent debugger attachment.
    ///
    /// This is a well-known iOS hardening technique. The app will be killed
    /// if a debugger attempts to attach after this call.
    ///
    /// Reference: Technical Q&A QA1631 (Apple)
    private func applyPtraceDenyAttach() {
        typealias PtraceFunc = @convention(c) (Int32, pid_t, UnsafeMutableRawPointer?, Int32) -> Int32
        let handle = dlopen(nil, RTLD_GLOBAL | RTLD_NOW)
        let sym = dlsym(handle, "ptrace")
        let ptraceFn = unsafeBitCast(sym, to: PtraceFunc.self)
        _ = ptraceFn(31 /* PT_DENY_ATTACH */, 0, nil, 0)
        dlclose(handle)
    }
}
