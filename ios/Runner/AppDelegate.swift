import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var vpnEventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    let vpnChannel = FlutterMethodChannel(
      name: "com.example.military_exam/vpn",
      binaryMessenger: messenger
    )
    vpnChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "prepare":
        VpnBridge.shared.prepare { ok in result(ok) }
      case "startVpn":
        VpnBridge.shared.start { ok in result(ok) }
      case "stopVpn":
        VpnBridge.shared.stop { ok in result(ok) }
      case "isActive":
        result(VpnBridge.shared.isActive())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let vpnEvents = FlutterEventChannel(
      name: "com.example.military_exam/vpn_events",
      binaryMessenger: messenger
    )
    vpnEvents.setStreamHandler(VpnEventStreamHandler { [weak self] sink in
      self?.vpnEventSink = sink
    })
  }
}

private final class VpnEventStreamHandler: NSObject, FlutterStreamHandler {
  private let onListenCallback: (FlutterEventSink?) -> Void

  init(onListen: @escaping (FlutterEventSink?) -> Void) {
    onListenCallback = onListen
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    onListenCallback(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onListenCallback(nil)
    return nil
  }
}
