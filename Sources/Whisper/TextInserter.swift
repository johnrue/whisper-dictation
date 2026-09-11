import AppKit

enum TextInserter {
    enum Outcome {
        case pasted
        case copiedOnly // Accessibility not granted; text left on the clipboard.
    }

    /// Inserts text into the frontmost app by putting it on the clipboard and
    /// synthesizing ⌘V. The transcript is deliberately left on the clipboard
    /// afterwards: if the target app didn't take the paste, ⌘V by hand still
    /// drops it in.
    @discardableResult
    static func insert(_ text: String) -> Outcome {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard AXIsProcessTrusted() else {
            return .copiedOnly
        }

        synthesizeCommandV()
        return .pasted
    }

    private static func synthesizeCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyVDown?.flags = .maskCommand
        keyVUp?.flags = .maskCommand
        keyVDown?.post(tap: .cghidEventTap)
        keyVUp?.post(tap: .cghidEventTap)
    }
}
