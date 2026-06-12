import AVFoundation

/// Captures microphone audio and converts it to 16 kHz mono Float32,
/// the input format Whisper expects.
final class AudioRecorder {
    /// Called on an arbitrary thread with a 0...1 level for the HUD meter.
    var levelHandler: ((Float) -> Void)?

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var samples: [Float] = []
    private let lock = NSLock()

    static let sampleRate: Double = 16000

    var isRunning: Bool { engine.isRunning }

    func start() throws {
        lock.lock()
        samples.removeAll()
        lock.unlock()

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
        ) else {
            throw RecorderError.formatFailure
        }
        converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.process(buffer: buffer, targetFormat: targetFormat)
        }
        engine.prepare()
        try engine.start()
    }

    /// Stops capture and returns everything recorded since start().
    func stop() -> [Float] {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        converter = nil
        lock.lock()
        defer { lock.unlock() }
        return samples
    }

    private func process(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        guard let converter else { return }

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
