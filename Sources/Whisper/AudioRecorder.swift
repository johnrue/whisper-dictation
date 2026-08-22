import AVFoundation

/// Captures microphone audio and converts it to 16 kHz mono Float32,
/// the input format Whisper expects.
///
/// A fresh AVAudioEngine is built for every capture (and rebuilt when the
/// input device changes mid-recording). Reusing one engine across device
/// changes — e.g. AirPods connecting — leaves it holding the old device's
/// format, and the resulting mismatch raises an Objective-C exception that
/// Swift can't catch, killing the app.
final class AudioRecorder {
    /// Called on an arbitrary thread with a 0...1 level for the HUD meter.
    var levelHandler: ((Float) -> Void)?
    /// Called on the main queue if capture dies mid-recording and can't be
    /// recovered (e.g. the mic disappeared). Samples so far remain available
    /// via stop().
    var onCaptureLost: (() -> Void)?

    private var engine: AVAudioEngine?
    private var configChangeObserver: NSObjectProtocol?
    private var rebuildTask: Task<Void, Never>?
    private var isCapturing = false
    private var samples: [Float] = []
    private let lock = NSLock()

    static let sampleRate: Double = 16000

    func start() throws {
        lock.lock()
        samples.removeAll()
        lock.unlock()
        isCapturing = true
        do {
            try startEngine()
        } catch {
            isCapturing = false
            throw error
        }
    }

    /// Stops capture and returns everything recorded since start().
    func stop() -> [Float] {
        isCapturing = false
        rebuildTask?.cancel()
        rebuildTask = nil
        tearDownEngine()
        lock.lock()
        defer { lock.unlock() }
        return samples
    }

    private func startEngine() throws {
        tearDownEngine()

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0 else {
            throw RecorderError.noInputDevice
        }
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Self.sampleRate,
            channels: 1,
            interleaved: false
        ), let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw RecorderError.formatFailure
        }
        // macOS 26 exposes the built-in mic as 3 channels; AVAudioConverter's
        // default multi->mono downmix then produces pure silence. Map channel 0
        // explicitly (also correct for mono devices).
        converter.channelMap = [0]

        // The converter is captured per-tap rather than stored on self so a
        // rebuild can never swap it out from under an in-flight tap callback.
        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.process(buffer: buffer, converter: converter, targetFormat: targetFormat)
        }
        engine.prepare()
        try engine.start()
        self.engine = engine

        // queue: nil is load-bearing: AVAudioEngine posts this from its internal
        // serial queue and the post blocks until queued observers run. With
        // queue: .main that wait can deadlock against a main thread that is
        // itself stopping the engine. Deliver inline, then hop to main.
        configChangeObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: nil
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.handleConfigurationChange() }
        }
    }

    /// The input device changed (AirPods connected, mic unplugged, …) and the
    /// engine stopped itself. Rebuild capture around the new device, keeping
    /// the samples recorded so far; converted output is always 16 kHz mono, so
    /// audio from both devices concatenates cleanly.
    private func handleConfigurationChange() {
        guard isCapturing else { return }
        rebuildTask?.cancel()
        rebuildTask = Task { @MainActor [weak self] in
            // The new device can take a moment to come up (Bluetooth especially).
            for _ in 0..<10 {
                guard let self, self.isCapturing, !Task.isCancelled else { return }
                if (try? self.startEngine()) != nil { return }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            guard let self, self.isCapturing else { return }
            self.isCapturing = false
            self.tearDownEngine()
            self.onCaptureLost?()
        }
    }

    private func tearDownEngine() {
        if let observer = configChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            configChangeObserver = nil
        }
        guard let engine else { return }
        self.engine = nil
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        // AVAudioEngine's dealloc can block on its internal audio queue; drop
        // the last reference off the main thread.
        DispatchQueue.global(qos: .utility).async {
            _ = engine
        }
    }

    private func process(buffer: AVAudioPCMBuffer, converter: AVAudioConverter, targetFormat: AVAudioFormat) {
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 16
        guard let output = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var consumed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, outStatus in
            if consumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            outStatus.pointee = .haveData
            return buffer
        }
        guard error == nil, output.frameLength > 0, let channel = output.floatChannelData?[0] else { return }

        let chunk = Array(UnsafeBufferPointer(start: channel, count: Int(output.frameLength)))
        lock.lock()
        samples.append(contentsOf: chunk)
        lock.unlock()

        let rms = sqrt(chunk.reduce(into: Float(0)) { $0 += $1 * $1 } / Float(chunk.count))
        levelHandler?(min(1, rms * 8))
    }

    enum RecorderError: LocalizedError {
        case noInputDevice
        case formatFailure

        var errorDescription: String? {
            switch self {
            case .noInputDevice: return "No microphone available"
            case .formatFailure: return "Could not configure audio format"
            }
        }
    }
}
