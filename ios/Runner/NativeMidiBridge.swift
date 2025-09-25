import Foundation
import AVFoundation
import Flutter

final class NativeMidiBridge {
    private static var player: AVMIDIPlayer?
    private static let session = AVAudioSession.sharedInstance()

    /// Call this from AppDelegate after creating the FlutterViewController.
    static func register(with controller: FlutterViewController) {
        let chan = FlutterMethodChannel(
            name: "idea/native_midi",
            binaryMessenger: controller.binaryMessenger
        )

        chan.setMethodCallHandler { call, result in
            switch call.method {
            case "midiLoad":
                guard
                    let args = call.arguments as? [String: Any],
                    let midiPath = args["midiPath"] as? String,
                    let sf2Path  = args["sf2Path"]  as? String
                else {
                    result(false)
                    return
                }
                result(load(midiPath: midiPath, sf2Path: sf2Path))

            case "midiPlay":
                // Start from beginning each time
                player?.currentPosition = 0
                player?.play { /* finished */ }
                result(true)

            case "midiStop":
                player?.stop()
                result(true)

            case "midiVolume":
                // AVMIDIPlayer has **no** volume property. We accept the call but ignore it.
                // Consider migrating to AVAudioEngine + AVAudioUnitSampler if you need volume.
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func load(midiPath: String, sf2Path: String) -> Bool {
        do {
            // Configure audio session for playback
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])

            let midiURL = URL(fileURLWithPath: midiPath)
            let sf2URL  = URL(fileURLWithPath: sf2Path)

            // Create and prepare the MIDI player
            let p = try AVMIDIPlayer(contentsOf: midiURL, soundBankURL: sf2URL)
            p.prepareToPlay()
            player = p
            return true
        } catch {
            print("MIDI load error: \(error)")
            player = nil
            return false
        }
    }
}
