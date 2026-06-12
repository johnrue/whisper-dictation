import AppKit

enum TextInserter {
    enum Outcome {
        case pasted
        case copiedOnly // Accessibility not granted; text left on the clipboard.
    }

    /// Inserts text into the frontmost app by putting it on the clipboard and
    /// synthesizing ⌘V, then restoring the previous clipboard string.
    @discardableResult
    static func insert(_ text: String) -> Outcome {
        let pasteboard = NSPasteboard.general
        let previous = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard AXIsProcessTrusted() else {
            return .copiedOnly
        }

        synthesizeCommandV()

        // Give the target app time to read the pasteboard before restoring.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Only restore if our text is still there (the user may have
            // copied something else in the meantime).
            if pasteboard.string(forType: .string) == text, let previous {
                pasteboard.clearContents()
                pasteboard.setString(previous, forType: .string)
            }
        }
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
