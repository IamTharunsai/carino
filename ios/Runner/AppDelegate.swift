import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private var screenshotChannel: FlutterMethodChannel?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // iOS can't block screenshots; it can tell us one happened. Vanish chats
    // turn that into an honest notice for both people.
    if let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "CarinoScreenshots")?.messenger() {
      screenshotChannel = FlutterMethodChannel(name: "carino/screenshots", binaryMessenger: messenger)
      NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: .main
      ) { [weak self] _ in
        self?.screenshotChannel?.invokeMethod("taken", arguments: nil)
      }
    }
  }
}
