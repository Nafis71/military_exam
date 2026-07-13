import Flutter
import UIKit

/// AdvanceRootDetectionPlugin — Flutter plugin entry point for iOS.
///
/// Wires all iOS detectors to the MethodChannel and EventChannel.
/// Reference: OWASP MASTG https://mas.owasp.org/MASTG/
public class AdvanceRootDetectionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var eventSink: FlutterEventSink?
    private var monitorTimer: Timer?

    // MARK: - Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "advance_root_detection/methods",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "advance_root_detection/threats",
            binaryMessenger: registrar.messenger()
        )

        let instance = AdvanceRootDetectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - MethodChannel handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "performCheck":
            let config = parseConfig(call.arguments)
            DispatchQueue.global(qos: .userInitiated).async {
                let report = self.buildReport(config: config)
                DispatchQueue.main.async { result(report) }
            }

        case "startMonitoring":
            let config = parseConfig(call.arguments)
            startMonitoring(config: config)
            result(nil)

        case "stopMonitoring":
            stopMonitoring()
            result(nil)

        case "verifyBeforeSensitiveOp":
            let config = parseConfig(call.arguments)
            DispatchQueue.global(qos: .userInitiated).async {
                let threats = self.collectAllThreats(config: config)
                let safe = !threats.contains { $0.severity == "critical" || $0.severity == "high" }
                DispatchQueue.main.async { result(safe) }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - EventChannel (StreamHandler)

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        stopMonitoring()
        return nil
    }

    // MARK: - Monitoring

    private func startMonitoring(config: DetectionConfig) {
        stopMonitoring()
        let interval = max(Double(config.monitoringIntervalSeconds), 5.0)
        DispatchQueue.main.async {
            self.monitorTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                let threats = self.collectAllThreats(config: config)
                for threat in threats {
                    self.eventSink?(threat.toMap())
                }
            }
        }
    }

    private func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    // MARK: - Detection orchestration

    private func collectAllThreats(config: DetectionConfig) -> [ThreatResult] {
        var threats: [ThreatResult] = []
        threats += JailbreakDetector.shared.detect()
        threats += HookDetector.shared.detect()
        threats += DebuggerDetector.shared.detect()
        threats += IntegrityDetector.shared.detect(config: config)
        threats += EnvironmentDetector.shared.detect()
        return threats
    }

    private func buildReport(config: DetectionConfig) -> [String: Any] {
        let threats = collectAllThreats(config: config)
        return [
            "detectedThreats": threats.map { $0.toMap() },
            "checkedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }

    // MARK: - Config parsing

    private func parseConfig(_ arguments: Any?) -> DetectionConfig {
        guard let args = arguments as? [String: Any] else { return DetectionConfig() }
        let ios = args["ios"] as? [String: Any] ?? [:]
        let intervalSeconds = (args["monitoringIntervalSeconds"] as? Int) ?? 30
        return DetectionConfig(
            bundleIds: (ios["bundleIds"] as? [String]) ?? [],
            teamId: ios["teamId"] as? String,
            monitoringIntervalSeconds: intervalSeconds
        )
    }
}

// MARK: - Shared data structures

struct DetectionConfig {
    let bundleIds: [String]
    let teamId: String?
    let monitoringIntervalSeconds: Int

    init(bundleIds: [String] = [], teamId: String? = nil, monitoringIntervalSeconds: Int = 30) {
        self.bundleIds = bundleIds
        self.teamId = teamId
        self.monitoringIntervalSeconds = monitoringIntervalSeconds
    }
}

struct ThreatResult {
    let category: String
    let description: String
    let severity: String
    let details: [String: String]?

    func toMap() -> [String: Any] {
        var map: [String: Any] = [
            "category": category,
            "description": description,
            "severity": severity
        ]
        if let d = details { map["details"] = d }
        return map
    }
}
