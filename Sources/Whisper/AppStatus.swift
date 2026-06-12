import Foundation

enum AppStatus: Equatable {
    /// Model is downloading or loading into memory.
    case startingUp
    case idle
    case recording
    case transcribing
    case error(String)

    var menuBarSymbol: String {
        switch self {
        case .startingUp: return "arrow.down.circle"
        case .idle: return "mic"
        case .recording: return "mic.fill"
        case .transcribing: return "waveform"
        case .error: return "exclamationmark.triangle"
        }
    }

    var label: String {
        switch self {
        case .startingUp: return "Loading model…"
        case .idle: return "Ready"
        case .recording: return "Recording…"
        case .transcribing: return "Transcribing…"
        case .error(let message): return "Error: \(message)"
        }
    }
}
