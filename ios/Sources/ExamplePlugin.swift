import SwiftRs
import Tauri
import UIKit
import WebKit
import AVFoundation

class SpeakArgs: Decodable {
    let text: String
}

class Speak {
    private static let voices = AVSpeechSynthesisVoice.speechVoices()
    // Make voiceSynth static to prevent deallocation
    private static let voiceSynth = AVSpeechSynthesizer()
    private let voiceToUse: AVSpeechSynthesisVoice?
    private var currentInvoke: Invoke?

    init() {
        // Print all English voices with their details
        for voice in Self.voices {
            if voice.language.starts(with: "en") {
                print("""
                    Name: \(voice.name)
                    Language: \(voice.language)
                    Quality: \(voice.quality.rawValue) // Raw value to see exact number
                    Identifier: \(voice.identifier)
                    --------------
                    """)
            }
        }

        // Try to find an enhanced or premium voice
        if #available(iOS 16.0, *) {
            voiceToUse = Self.voices.first { voice in
                voice.language.starts(with: "en") &&
                (voice.quality == .premium || voice.quality == .enhanced)
            }
        } else {
            voiceToUse = Self.voices.first { voice in
                voice.language.starts(with: "en") &&
                voice.quality == .enhanced
            }
        }

        if let selectedVoice = voiceToUse {
            print("Selected voice: \(selectedVoice.name) with quality \(selectedVoice.quality.rawValue)")
        } else {
            print("No enhanced or premium voice found")
        }
    }

    func sayThis(_ phrase: String, invoke: Invoke) {
        currentInvoke = invoke
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.voice = voiceToUse
        utterance.rate = 0.5
        Self.voiceSynth.speak(utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Speech finished successfully")
        currentInvoke?.resolve()
        currentInvoke = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("Speech was cancelled")
        currentInvoke?.reject("Speech was cancelled")
        currentInvoke = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Speech started")
    }
}

class ExamplePlugin: Plugin {
    // Keep static instance to ensure it lives for the duration of the app
    private static let speaker = Speak()

    @objc public func speak(_ invoke: Invoke) throws {
        let args = try invoke.parseArgs(SpeakArgs.self)
        Self.speaker.sayThis(args.text, invoke: invoke)
    }
}

@_cdecl("init_plugin_tts")
func initPlugin() -> Plugin {
    return ExamplePlugin()
}
