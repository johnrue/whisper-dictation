// Renders the app icon: indigo gradient squircle with a white waveform.
// Run via scripts/make-icon.sh, which wraps the output into AppIcon.icns.
import AppKit

let canvas: CGFloat = 1024
let image = NSImage(size: NSSize(width: canvas, height: canvas))
image.lockFocus()

// macOS icons leave ~10% transparent margin around a rounded rect.
let inset: CGFloat = 100
let rect = NSRect(x: inset, y: inset, width: canvas - inset * 2, height: canvas - inset * 2)
let shape = NSBezierPath(roundedRect: rect, xRadius: 185, yRadius: 185)

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.31, green: 0.18, blue: 0.92, alpha: 1),
    NSColor(calibratedRed: 0.13, green: 0.45, blue: 0.95, alpha: 1),
])!
gradient.draw(in: shape, angle: -60)

// Soft highlight across the top for depth.
let highlight = NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.18),
    NSColor.white.withAlphaComponent(0.0),
])!
shape.addClip()
highlight.draw(in: NSRect(x: inset, y: rect.midY, width: rect.width, height: rect.height / 2), angle: -90)

// Waveform: symmetric rounded bars, taller toward the center.
let barCount = 9
let barWidth: CGFloat = 38
let spacing: CGFloat = 34
let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
let startX = (canvas - totalWidth) / 2
let heights: [CGFloat] = [120, 220, 330, 260, 460, 260, 330, 220, 120]

NSColor.white.setFill()
for (index, height) in heights.enumerated() {
    let x = startX + CGFloat(index) * (barWidth + spacing)
    let bar = NSRect(x: x, y: (canvas - height) / 2, width: barWidth, height: height)
    NSBezierPath(roundedRect: bar, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:])
else {
    fatalError("Could not render icon")
}
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png")
try png.write(to: out)
print("Wrote \(out.path)")
