import AppKit
import SwiftUI

/// Floating, non-activating panel shown bottom-center while recording or
/// transcribing — the visual feedback that the app is listening.
@MainActor
final class HUDController {
    weak var controller: AppController?

    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    func show() {
        hideTask?.cancel()
        hideTask = nil
        let panel = ensurePanel()
        position(panel)
        panel.orderFrontRegardless()
    }

    func hide(after delay: TimeInterval) {
        hideTask?.cancel()
        hideTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.panel?.orderOut(nil)
        }
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }

        let size = NSSize(width: 240, height: 52)
        let newPanel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.level = .statusBar
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.ignoresMouseEvents = true
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.isReleasedWhenClosed = false

        if let controller {
            let view = HUDView().environmentObject(controller)
            newPanel.contentView = NSHostingView(rootView: view)
        }

        panel = newPanel
        return newPanel
    }

    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.minY + 28
        )
        panel.setFrameOrigin(origin)
    }
}

struct HUDView: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        HStack(spacing: 10) {
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.15)))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.15), value: controller.audioLevel)
    }

    @ViewBuilder
    private var content: some View {
        if let message = controller.hudMessage {
            Text(message)
                .font(.callout)
        } else {
            switch controller.status {
            case .recording:
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
                LevelMeter(level: controller.audioLevel)
            case .transcribing:
                ProgressView()
                    .controlSize(.small)
                Text("Transcribing…")
                    .font(.callout)
            default:
                EmptyView()
            }
        }
    }
}

/// Simple animated bar meter driven by the live mic level.
struct LevelMeter: View {
    let level: Float
    private let barCount = 14

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                let threshold = Float(index) / Float(barCount)
                Capsule()
                    .fill(level > threshold ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 4, height: barHeight(index))
            }
        }
    }

    private func barHeight(_ index: Int) -> CGFloat {
        // Taller bars toward the middle, like a waveform.
        let center = Double(barCount - 1) / 2
        let distance = abs(Double(index) - center) / center
        return 8 + CGFloat((1 - distance) * 12)
    }
}
