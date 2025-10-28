/*
TextToSpeech.swift

Abstract:
Text-to-Speech utility for providing audio feedback.
Provides an easy-to-use interface for speaking text to help visually impaired users.

QUICK START:
-----------
Simply call TextToSpeech.shared to speak any text anywhere in your app.

BASIC USAGE:
-----------
// Simple text
TextToSpeech.shared.speak("42")

// With priority (high for urgent warnings)
TextToSpeech.shared.speak("Danger ahead", priority: .high)

// Stop current speech
TextToSpeech.shared.stop()

// Check if speaking
if TextToSpeech.shared.isSpeaking() {
    // Currently speaking
}

CONVENIENCE METHODS:
-------------------
// Speak warning (automatically adds "Warning:" prefix)
TextToSpeech.shared.speakWarning("Low ceiling detected")

// Speak clearance message
TextToSpeech.shared.speakClearance("Path clear")

// Speak distance
TextToSpeech.shared.speakDistance(distance: 0.5)  // 50cm

CUSTOM SPEECH:
-------------
TextToSpeech.shared.speak(
    "Message", 
    rate: 0.5,     // 0.0-1.0 (slower to faster)
    volume: 1.0,   // 0.0-1.0 
    pitch: 1.0     // 0.5-2.0
)

PROPERTIES:
----------
- Priority: .high (urgent, faster), .normal, .low (info)
- Language: English (en-US)
- Auto-ducking: Automatically lowers volume of other audio
- Interruption: New speech automatically stops previous speech
*/

import Foundation
import AVFoundation

class TextToSpeech {
    
    // Singleton instance for easy access throughout the app
    static let shared = TextToSpeech()
    
    // AVSpeechSynthesizer for converting text to speech
    private let synthesizer = AVSpeechSynthesizer()
    
    // Private initializer to enforce singleton pattern
    private init() {
        configureAudioSession()
    }
    
    // Configure audio session for optimal speech quality
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    // Main function to speak text
    // Usage: TextToSpeech.shared.speak("Warning, obstacle at 50 centimeters")
    func speak(_ text: String, priority: SpeechPriority = .normal) {
        // Stop any currently speaking utterance
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure utterance based on priority
        switch priority {
        case .high:
            utterance.rate = 0.55  // Slightly faster for urgency
            utterance.volume = 1.0
            utterance.pitchMultiplier = 1.1  // Slightly higher pitch for attention
        case .normal:
            utterance.rate = 0.5
            utterance.volume = 1.0
            utterance.pitchMultiplier = 1.0
        case .low:
            utterance.rate = 0.45  // Slower for less urgent information
            utterance.volume = 0.9
            utterance.pitchMultiplier = 0.95
        }
        
        // Set language to English
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Speak the text
        synthesizer.speak(utterance)
    }
    
    // Speak with custom rate and volume
    // Usage: TextToSpeech.shared.speak("Message", rate: 0.5, volume: 1.0)
    func speak(_ text: String, rate: Float = 0.5, volume: Float = 1.0, pitch: Float = 1.0) {
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.volume = volume
        utterance.pitchMultiplier = pitch
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
    }
    
    // Stop current speech immediately
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // Check if currently speaking
    func isSpeaking() -> Bool {
        return synthesizer.isSpeaking
    }
    
    // Speak a distance warning with formatted text
    // Usage: TextToSpeech.shared.speakDistance(distance: 0.5, unit: .meters)
    func speakDistance(distance: Float, unit: DistanceUnit = .meters) {
        let distanceInCm = Int(distance * 100)
        let text: String
        
        switch unit {
        case .meters:
            text = "Obstacle detected at \(distanceInCm) centimeters ahead"
        case .inches:
            let inches = Int(distance * 39.37)
            text = "Obstacle detected at \(inches) inches ahead"
        }
        
        speak(text, priority: .high)
    }
    
    // Speak a general warning message
    // Usage: TextToSpeech.shared.speakWarning("Low ceiling detected")
    func speakWarning(_ message: String) {
        speak("Warning: \(message)", priority: .high)
    }
    
    // Speak a clearance message (safe path)
    // Usage: TextToSpeech.shared.speakClearance("Path clear ahead")
    func speakClearance(_ message: String) {
        speak(message, priority: .low)
    }
}

// Enum for speech priority levels
enum SpeechPriority {
    case high    // Urgent warnings
    case normal  // Standard information
    case low     // General information
}

// Enum for distance units
enum DistanceUnit {
    case meters
    case inches
}

