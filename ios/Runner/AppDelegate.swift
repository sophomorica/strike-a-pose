import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeSnapsFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    excludeSnapsFromBackup()
  }

  func excludeSnapsFromBackup() {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let snaps = docs.appendingPathComponent("snaps", isDirectory: true)
    try? FileManager.default.createDirectory(at: snaps, withIntermediateDirectories: true)
    var url = snaps
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? url.setResourceValues(values)
    if let files = try? FileManager.default.subpathsOfDirectory(atPath: snaps.path) {
      for file in files {
        var fileUrl = snaps.appendingPathComponent(file)
        var fileValues = URLResourceValues()
        fileValues.isExcludedFromBackup = true
        try? fileUrl.setResourceValues(fileValues)
      }
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StrikeSettings") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "strikeapose/settings",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "open" {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(nil)
          return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
