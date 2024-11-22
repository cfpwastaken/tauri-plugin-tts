import SwiftRs
import Tauri
import UIKit
import WebKit
import AVFoundation

class SpeakArgs: Decodable {
    let text: String
}

enum SpeakError: Error {
    case noEnhancedVoiceFound
    case voiceInitializationError(String)
}


class Speak: NSObject, AVSpeechSynthesizerDelegate {
    private static let voices = AVSpeechSynthesisVoice.speechVoices()
    // Make voiceSynth static to prevent deallocation
    private static let voiceSynth = AVSpeechSynthesizer()
    private var voiceToUse: AVSpeechSynthesisVoice?
    private var currentInvoke: Invoke?

    override init() {
        super.init()
        Self.voiceSynth.delegate = self

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
            if let selectedVoice = Self.voices.first(where: { voice in
                voice.language.starts(with: "en") &&
                (voice.quality == .premium || voice.quality == .enhanced)
            }) {
                self.voiceToUse = selectedVoice
                print("Selected voice: \(selectedVoice.name) with quality \(selectedVoice.quality.rawValue)")
            } else {
//                throw SpeakError.noEnhancedVoiceFound
            }
        } else {
            if let selectedVoice = Self.voices.first(where: { voice in
                voice.language.starts(with: "en") &&
                voice.quality == .enhanced
            }) {
                self.voiceToUse = selectedVoice
                print("Selected voice: \(selectedVoice.name) with quality \(selectedVoice.quality.rawValue)")
            } else {
//                throw SpeakError.noEnhancedVoiceFound
            }
        }
        
    }

    func sayThis(_ phrase: String, invoke: Invoke) throws {
//        ensure that voice was found
        guard let voiceToUse else { throw SpeakError.noEnhancedVoiceFound }
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
    private static var speaker: Speak?

    // Non-throwing required initializer
    override required init() {
        super.init()
        do {
            Self.speaker = try Speak()
        } catch {
            // Handle the error appropriately
            print("Failed to initialize speaker: \(error)")
            // You might want to set some error state here
        }
    }

    @objc public func speak(_ invoke: Invoke) throws {
        guard let speaker = Self.speaker else {
            throw SpeakError.voiceInitializationError("Speaker not initialized")
        }
        let args = try invoke.parseArgs(SpeakArgs.self)
        try speaker.sayThis(args.text, invoke: invoke)
    }
    
    
}



@_cdecl("init_plugin_tts")
func initPlugin() -> Plugin {
    return ExamplePlugin()
}
