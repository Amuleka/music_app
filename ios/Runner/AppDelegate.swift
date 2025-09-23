import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // IMPORTANT: register Flutter plugins (just_audio, path_provider, etc.)
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    NativeBridge.setupChannels(controller)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
