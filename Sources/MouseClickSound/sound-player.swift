import AVFoundation

enum Sound: String, CaseIterable, Identifiable {
    case click, press, release

    var id: String { rawValue }
    var title: String {
        switch self {
        case .click: "Complete click"
        case .press: "Press"
        case .release: "Release"
        }
    }
}

@MainActor
final class SoundPlayer {
    private var voices: [Sound: [AVAudioPlayer]] = [:]
    private var nextVoice: [Sound: Int] = [:]

    init() throws {
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
                throw CocoaError(.fileNoSuchFile)
            }
            voices[sound] = try (0..<6).map { _ in
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                return player
            }
        }
    }

    func play(_ sound: Sound, volume: Double) {
        guard let pool = voices[sound], !pool.isEmpty else { return }
        if sound == .click {
            for voice in pool where voice.isPlaying { voice.stop() }
        }
        let index = nextVoice[sound, default: 0] % pool.count
        nextVoice[sound] = index + 1
        let player = pool[index]
        player.currentTime = 0
        player.volume = Float(volume)
        player.play()
    }

    func stop() {
        for pool in voices.values {
            for player in pool { player.stop() }
        }
    }
}
