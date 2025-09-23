import Foundation
import AVFoundation

final class IdeaRecorder: NSObject, AVAudioRecorderDelegate {
    private let session = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?
    private(set) var currentURL: URL?

    enum RecError: LocalizedError {
        case micDenied
        case micUndetermined
        case startFailed

        var errorDescription: String? {
            switch self {
            case .micDenied: return "Microphone permission denied in Settings."
            case .micUndetermined: return "Microphone permission not determined yet."
            case .startFailed: return "Failed to start recording."
            }
        }
    }

    /// Start recording. On first run, this will trigger the iOS mic prompt and throw `.micUndetermined`.
    /// Call again after the user grants permission.
    func start() throws {
        // 0) Permission handling (pre-iOS 17 friendly)
        switch session.recordPermission {
        case .denied:
            throw RecError.micDenied
        case .undetermined:
            // Triggers the system prompt asynchronously; tell caller to try again.
            session.requestRecordPermission { _ in }
            throw RecError.micUndetermined
        case .granted:
            break
        @unknown default:
            throw RecError.micDenied
        }

        // 1) Configure audio session
        try session.setCategory(.playAndRecord,
                                mode: .default,
                                options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: [])

        // 2) Prepare file URL
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("idea_\(UUID().uuidString).m4a")
        currentURL = url

        // 3) Recorder settings (AAC 48k mono ~96kbps)
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 96000
        ]

        let r = try AVAudioRecorder(url: url, settings: settings)
        r.isMeteringEnabled = true
        r.delegate = self
        guard r.record() else { throw RecError.startFailed }
        recorder = r

        // 4) Handle interruptions (calls, Siri, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    func stop() -> String {
        defer {
            recorder = nil
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
        }
        recorder?.stop()
        return currentURL?.path ?? ""
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }
        if type == .began {
            recorder?.pause()
        } else if type == .ended {
            recorder?.record()
        }
    }
}
