import Foundation
import NetworkExtension

final class VpnBridge: NSObject {
    static let shared = VpnBridge()

    private let providerBundleId = "com.example.military_exam.PacketTunnel"
    private var manager: NETunnelProviderManager?

    func prepare(completion: @escaping (Bool) -> Void) {
        loadManager { manager, error in
            if error != nil {
                completion(false)
                return
            }
            completion(manager != nil)
        }
    }

    func start(completion: @escaping (Bool) -> Void) {
        loadManager { [weak self] manager, error in
            guard let self, let manager, error == nil else {
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
                if saveError != nil {
                    completion(false)
                    return
                }
                manager.loadFromPreferences { loadError in
                    if loadError != nil {
                        completion(false)
                        return
                    }
                    do {
                        try manager.connection.startVPNTunnel()
                        completion(true)
                    } catch {
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

    func isActive() -> Bool {
        guard let status = manager?.connection.status else { return false }
        return status == .connected || status == .connecting || status == .reasserting
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
}
