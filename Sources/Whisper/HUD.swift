import AppKit
import DynamicNotchKit
import SwiftUI

/// Dynamic-Island-style overlay shown while recording or transcribing — the
/// visual feedback that the app is listening. Expands from the notch on
/// notched displays and floats as a pill everywhere else.
@MainActor
final class HUDController {
    weak var controller: AppController?

    private typealias Notch = DynamicNotch<AnyView, EmptyView, EmptyView>

    private var notch: Notch?
    private var builtForNotchedScreen = false
    private var hideTask: Task<Void, Never>?
    private var work: Task<Void, Never> = Task {}

    func show() {
        hideTask?.cancel()
        hideTask = nil

        guard let screen = targetScreen(), let notch = notch(for: screen) else { return }
        enqueue {
            await notch.expand(on: screen)
            // The panel is rebuilt on every present, so this can't be set once.
            notch.windowController?.window?.ignoresMouseEvents = true
        }
    }

    func hide(after delay: TimeInterval) {
        hideTask?.cancel()
        hideTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled, let self, let notch = self.notch else { return }
            self.enqueue { await notch.hide() }
        }
    }

    /// Serializes presentation so a queued hide can never dismiss a show that
    /// was requested after it.
    private func enqueue(_ operation: @escaping @MainActor () async -> Void) {
        let previous = work
        work = Task { @MainActor in
            _ = await previous.value
            await operation()
        }
    }

    private func notch(for screen: NSScreen) -> Notch? {
        guard let controller else { return nil }

        let notched = hasNotch(screen)
        if let notch, builtForNotchedScreen == notched { return notch }

        // Content is captured when the notch is created, so switching between a
        // notched and a plain screen needs a fresh one.
        if let stale = notch {
            enqueue { await stale.hide() }
        }

        let content = AnyView(HUDView(onNotch: notched).environmentObject(controller))
        let notch = Notch(hoverBehavior: [], style: .auto) { content }
        self.notch = notch
        builtForNotchedScreen = notched
        return notch
    }

    private func targetScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    /// Mirrors the check `.auto` styling makes when picking notch vs. floating.
    private func hasNotch(_ screen: NSScreen) -> Bool {
        screen.auxiliaryTopLeftArea != nil && screen.auxiliaryTopRightArea != nil
    }
}

struct HUDView: View {
    /// A notch expansion draws on black; the floating pill uses system material.
    let onNotch: Bool

    @EnvironmentObject private var controller: AppController
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        HStack(spacing: 10) {
            content
        }
        .frame(minWidth: 180, minHeight: 26)
        .environment(\.colorScheme, onNotch ? .dark : systemColorScheme)
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
                WaveformView(level: controller.audioLevel)
            case .transcribing:
                Image(systemName: "mic.fill")
                    .foregroundStyle(.secondary)
                WaveformView(level: 0, shimmering: true)
            default:
                EmptyView()
            }
        }
    }
}

/// Bar waveform driven by the live mic level. When `shimmering` the bars sit
/// flat and a highlight sweeps across them, standing in for a progress spinner.
struct WaveformView: View {
    let level: Float
    var shimmering: Bool = false

    private let barCount = 13
    private let barWidth: CGFloat = 4
    private let barSpacing: CGFloat = 3
    private let minHeight: CGFloat = 5
    private let maxHeight: CGFloat = 22

    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        bars
            .frame(height: maxHeight)
            .overlay { shimmer }
            .animation(.easeOut(duration: 0.08), value: level)
    }

    private var bars: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(shimmering ? Color.secondary.opacity(0.55) : Color.accentColor)
                    .frame(width: barWidth, height: height(at: index))
            }
        }
    }

    @ViewBuilder
    private var shimmer: some View {
        if shimmering {
            GeometryReader { geometry in
                let width = geometry.size.width
                let bandWidth = width * 0.55
                LinearGradient(
                    colors: [.clear, .white.opacity(0.85), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: bandWidth, height: geometry.size.height)
                .offset(x: -bandWidth + shimmerPhase * (width + bandWidth))
            }
            .mask(bars)
            .allowsHitTesting(false)
            .onAppear {
                shimmerPhase = 0
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1
                }
            }
        }
    }

    private func height(at index: Int) -> CGFloat {
        guard !shimmering else { return minHeight }

        // Gate out room noise, then renormalize so silence reads as flat.
        let gated = max(0, Double(level) - 0.05) / 0.95
        // Speech lives in the low end of the range, so lift it.
        let amplitude = pow(gated, 0.55)

        // Peak in the middle, taper toward the ends.
        let center = Double(barCount - 1) / 2
        let distance = abs(Double(index) - center) / center
        let envelope = max(0.18, 0.96 - distance * 0.78)
        let variation = 0.92 + 0.08 * cos(Double(index) * 1.45)

        let span = Double(maxHeight - minHeight)
        return minHeight + CGFloat(span * amplitude * envelope * variation)
    }
}
