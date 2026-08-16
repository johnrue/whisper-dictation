import AppKit

/// Short built-in system cues marking the start and end of a recording.
@MainActor
enum SoundPlayer {
    private static let startCue = cue(named: "Tink")
    private static let stopCue = cue(named: "Pop")

    static func playStart() {
        play(startCue)
    }

    static func playStop() {
        play(stopCue)
    }

    /// Quiet enough to sit under speech without being startling.
    private static func cue(named name: String) -> NSSound? {
        let sound = NSSound(named: name)
        sound?.volume = 0.35
        return sound
    }

    private static func play(_ sound: NSSound?) {
        guard let sound else { return }
        // A cue can still be playing from a very short previous session;
        // NSSound ignores play() while it is.
        if sound.isPlaying { sound.stop() }
        sound.play()
    }
}
