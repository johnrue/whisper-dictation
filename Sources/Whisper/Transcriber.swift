import Foundation
import WhisperKit

/// Wraps WhisperKit: downloads/loads the model and runs transcription.
final class Transcriber {
    private var whisperKit: WhisperKit?
    private(set) var loadedModel: String?

    func load(model: String) async throws {
        guard model != loadedModel || whisperKit == nil else { return }
        whisperKit = nil
        loadedModel = nil
        let config = WhisperKitConfig(model: model)
        whisperKit = try await WhisperKit(config)
        loadedModel = model
    }

    var isLoaded: Bool { whisperKit != nil }

    func transcribe(samples: [Float], language: String?) async throws -> String {
        guard let whisperKit else { throw TranscriberError.modelNotLoaded }
        let options = DecodingOptions(
            task: .transcribe,
            language: language
        )
        let results = try await whisperKit.transcribe(audioArray: samples, decodeOptions: options)
        let text = results.map(\.text).joined(separator: " ")
        return Self.cleanUp(text)
    }

    /// Whisper output includes leading spaces per segment and sometimes
    /// special tokens for silence; normalize to plain insertable text.
    static func cleanUp(_ raw: String) -> String {
        var text = raw
        // Remove special tokens like <|startoftranscript|> if they leak through.
        text = text.replacingOccurrences(of: #"<\|[^|]*\|>"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum TranscriberError: LocalizedError {
        case modelNotLoaded

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded: return "Model not loaded yet"
            }
        }
    }
}
