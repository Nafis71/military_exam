import Flutter
import Foundation
import NetworkExtension

final class VpnBridge: NSObject {
    static let shared = VpnBridge()

    private let providerBundleId = "com.example.militaryExam.PacketTunnel"
    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?
    private var eventSink: FlutterEventSink?

    func configureEventSink(_ sink: FlutterEventSink?) {
        eventSink = sink
        if sink != nil {
            startObservingStatus()
            loadManager { [weak self] _, _ in
                self?.emitStatusIfDisconnected()
            }
        } else {
            stopObservingStatus()
        }
    }

    func prepare(completion: @escaping (Bool) -> Void) {
        loadManager { manager, error in
            if let error {
                self.logError("prepare loadManager failed", error: error)
                completion(false)
                return
            }
            completion(manager != nil)
        }
    }

    func start(completion: @escaping (Bool) -> Void) {
        loadManager { [weak self] manager, error in
            guard let self, let manager, error == nil else {
                if let error {
                    self?.logError("start loadManager failed", error: error)
                }
                completion(false)
                return
            }

            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.providerBundleIdentifier = self.providerBundleId
            tunnelProtocol.serverAddress = "127.0.0.1"
            manager.protocolConfiguration = tunnelProtocol
            manager.localizedDescription = "Military Exam Lockdown"
            manager.isEnabled = true

            manager.saveToPreferences { saveError in
                if let saveError {
                    self.logError("saveToPreferences failed", error: saveError)
                    completion(false)
                    return
                }
                manager.loadFromPreferences { loadError in
                    if let loadError {
                        self.logError("loadFromPreferences failed", error: loadError)
                        completion(false)
                        return
                    }
                    self.manager = manager
                    do {
                        try manager.connection.startVPNTunnel()
                        completion(true)
                    } catch {
                        self.logError("startVPNTunnel failed", error: error)
                        completion(false)
                    }
                }
            }
        }
    }

    func stop(completion: @escaping (Bool) -> Void) {
        manager?.connection.stopVPNTunnel()
        completion(true)
    }

    func isActive(completion: @escaping (Bool) -> Void) {
        loadManager { [weak self] manager, error in
            guard let self, let manager, error == nil else {
                if let error {
                    self?.logError("isActive loadManager failed", error: error)
                }
                completion(false)
                return
            }
            completion(self.isConnectedStatus(manager.connection.status))
        }
    }

    private func isConnectedStatus(_ status: NEVPNStatus) -> Bool {
        status == .connected || status == .connecting || status == .reasserting
    }

    private func loadManager(completion: @escaping (NETunnelProviderManager?, Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let error {
                completion(nil, error)
                return
            }
            let existing = managers?.first { manager in
                (manager.protocolConfiguration as? NETunnelProviderProtocol)?
                    .providerBundleIdentifier == self.providerBundleId
            }
            if let existing {
                self.manager = existing
                completion(existing, nil)
                return
            }
            let manager = NETunnelProviderManager()
            self.manager = manager
            completion(manager, nil)
        }
    }

    private func startObservingStatus() {
        stopObservingStatus()
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.emitStatusIfDisconnected()
        }
    }

    private func stopObservingStatus() {
        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
            self.statusObserver = nil
        }
    }

    private func emitStatusIfDisconnected() {
        guard let manager else { return }
        let status = manager.connection.status
        if status == .disconnected || status == .invalid {
            eventSink?("disconnected")
        }
    }

    private func logError(_ message: String, error: Error) {
        #if DEBUG
        let nsError = error as NSError
        print("[VpnBridge] \(message): \(nsError.domain) (\(nsError.code)) \(nsError.localizedDescription)")
        #endif
    }
}
