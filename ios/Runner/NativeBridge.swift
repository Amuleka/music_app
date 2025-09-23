import Foundation
import Flutter

final class NativeBridge {
    private static let recorder = IdeaRecorder()

    static func setupChannels(_ controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "idea/native",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "startRecord":
                do {
                    try recorder.start()
                    result(true)
                } catch {
                    result(FlutterError(code: "REC_START_ERR",
                                        message: error.localizedDescription,
                                        details: nil))
                }

            case "stopRecord":
                let path = recorder.stop()
                result(path)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
