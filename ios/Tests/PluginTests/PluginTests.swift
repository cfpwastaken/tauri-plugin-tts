import XCTest
import Tauri
import AVFoundation
@testable import tauri_plugin_tts

final class ExamplePluginTests: XCTestCase, AVSpeechSynthesizerDelegate {
    var didStartSpeaking = false

    @available(iOS 13.0, *)
    func testExample() throws {
        let plugin = ExamplePlugin()

        // Access the synthesizer and set delegate
        let mirror = Mirror(reflecting: plugin)
        if let synthesizer = mirror.children.first(where: { $0.label == "synthesizer" })?.value as? AVSpeechSynthesizer {
            synthesizer.delegate = self
        }

        let testData = """
        {"text": "I recommend taking advantage of the beautiful day outside by going for a walk in the park. It’s a great way to relax and enjoy some fresh air!"}
        """

        let mockInvoke = Invoke(
            command: "speak",
            callback: 1,
            error: 2,
            sendResponse: { (callbackId, response) in
                XCTAssertEqual(callbackId, 1)
                XCTAssertNil(response)
            },
            sendChannelData: { (_, _) in },
            data: testData
        )

        try plugin.speak(mockInvoke)

        // Wait for speech to start
        let expectation = XCTestExpectation(description: "Speech started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            XCTAssertTrue(self.didStartSpeaking, "Speech synthesis should have started")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        didStartSpeaking = true
    }
}
