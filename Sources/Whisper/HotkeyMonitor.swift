import AppKit

/// Watches for the configured modifier key globally (and locally, for when our
/// own windows have focus). Global monitoring only delivers events once the
/// app is trusted for Accessibility.
final class HotkeyMonitor {
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var key: HotkeyKey = .rightOption
    private var mode: HotkeyMode = .hold
    private var isPressed = false
    private var toggleActive = false

    func configure(key: HotkeyKey, mode: HotkeyMode) {
        self.key = key
        self.mode = mode
        isPressed = false
        toggleActive = false
        install()
    }

    /// Re-installs the event monitors. Safe to call repeatedly; used after the
    /// user grants Accessibility so the global monitor actually starts working.
    func install() {
        remove()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func remove() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(_ event: NSEvent) {
        guard event.keyCode == key.keyCode else { return }
        let pressed = event.modifierFlags.contains(key.flag)
        guard pressed != isPressed else { return }
        isPressed = pressed

        switch mode {
        case .hold:
            pressed ? onKeyDown?() : onKeyUp?()
        case .toggle:
            guard pressed else { return }
            toggleActive.toggle()
            toggleActive ? onKeyDown?() : onKeyUp?()
        }
    }

    deinit {
        remove()
    }
}
