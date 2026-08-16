import AppKit
import Foundation

enum SettingsKey {
    static let model = "modelName"
    static let language = "language"
    static let hotkeyKey = "hotkeyKey"
    static let hotkeyMode = "hotkeyMode"
    static let playSounds = "playSounds"
}

struct ModelOption: Identifiable {
    let id: String
    let label: String
    let detail: String

    static let all: [ModelOption] = [
        .init(id: "openai_whisper-tiny", label: "Tiny", detail: "fastest, least accurate (~150 MB)"),
        .init(id: "openai_whisper-base", label: "Base", detail: "fast (~290 MB)"),
        .init(id: "openai_whisper-small", label: "Small", detail: "good balance (~970 MB)"),
        .init(id: "openai_whisper-large-v3-v20240930_turbo", label: "Large v3 Turbo", detail: "best accuracy (~1.6 GB)"),
    ]

    static let defaultID = "openai_whisper-large-v3-v20240930_turbo"
}

struct LanguageOption: Identifiable {
    let id: String
    let label: String

    static let all: [LanguageOption] = [
        .init(id: "auto", label: "Auto-detect"),
        .init(id: "en", label: "English"),
        .init(id: "es", label: "Spanish"),
        .init(id: "fr", label: "French"),
        .init(id: "de", label: "German"),
        .init(id: "it", label: "Italian"),
        .init(id: "pt", label: "Portuguese"),
        .init(id: "nl", label: "Dutch"),
        .init(id: "ja", label: "Japanese"),
        .init(id: "zh", label: "Chinese"),
        .init(id: "ko", label: "Korean"),
        .init(id: "ru", label: "Russian"),
        .init(id: "hi", label: "Hindi"),
        .init(id: "ar", label: "Arabic"),
    ]
}

enum HotkeyKey: String, CaseIterable, Identifiable {
    case rightOption
    case rightCommand

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rightOption: return "Right Option (⌥)"
        case .rightCommand: return "Right Command (⌘)"
        }
    }

    var keyCode: UInt16 {
        switch self {
        case .rightOption: return 61
        case .rightCommand: return 54
        }
    }

    var flag: NSEvent.ModifierFlags {
        switch self {
        case .rightOption: return .option
        case .rightCommand: return .command
        }
    }
}

enum HotkeyMode: String, CaseIterable, Identifiable {
    case hold
    case toggle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hold: return "Hold to record"
        case .toggle: return "Press to start / stop"
        }
    }
}

struct AppSettings {
    var model: String
    var language: String
    var hotkeyKey: HotkeyKey
    var hotkeyMode: HotkeyMode
    var playSounds: Bool

    /// Language code for Whisper, nil means auto-detect.
    var whisperLanguage: String? {
        language == "auto" ? nil : language
    }

    static func load() -> AppSettings {
        let defaults = UserDefaults.standard
        return AppSettings(
            model: defaults.string(forKey: SettingsKey.model) ?? ModelOption.defaultID,
            language: defaults.string(forKey: SettingsKey.language) ?? "auto",
            hotkeyKey: HotkeyKey(rawValue: defaults.string(forKey: SettingsKey.hotkeyKey) ?? "") ?? .rightOption,
            hotkeyMode: HotkeyMode(rawValue: defaults.string(forKey: SettingsKey.hotkeyMode) ?? "") ?? .hold,
            // bool(forKey:) reads an unset key as false; sounds default to on.
            playSounds: defaults.object(forKey: SettingsKey.playSounds) as? Bool ?? true
        )
    }
}
