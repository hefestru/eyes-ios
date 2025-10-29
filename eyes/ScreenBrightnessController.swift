/*
ScreenBrightnessController.swift

Abstract:
Utility class for controlling screen brightness with double-tap gesture.
Provides audio feedback (Text-to-Speech) to announce screen on/off state.
Designed for accessibility, allowing users to save battery by dimming the screen.

USAGE:
------
// In SwiftUI view
@StateObject private var brightnessController = ScreenBrightnessController()

// Add double tap gesture
.onTapGesture(count: 2) {
    brightnessController.toggleBrightness()
}

// Restore brightness when view disappears
.onDisappear {
    brightnessController.restoreBrightness()
}

// Initialize when view appears
.onAppear {
    brightnessController.initialize()
}
*/

import Foundation
import SwiftUI
import UIKit

// Extension for notification name
extension Notification.Name {
    static let statusBarVisibilityChanged = Notification.Name("statusBarVisibilityChanged")
}

// UIViewController that controls status bar visibility
class StatusBarController: UIViewController {
    static var isStatusBarHidden: Bool = false
    
    override var prefersStatusBarHidden: Bool {
        return StatusBarController.isStatusBarHidden
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Listen for status bar visibility changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStatusBar),
            name: .statusBarVisibilityChanged,
            object: nil
        )
    }
    
    @objc private func updateStatusBar() {
        setNeedsStatusBarAppearanceUpdate()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Wrapper to use StatusBarController in SwiftUI
struct StatusBarControllerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> StatusBarController {
        let controller = StatusBarController()
        // Ensure controller is part of view hierarchy
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: StatusBarController, context: Context) {
        // Force status bar update when state changes
        uiViewController.setNeedsStatusBarAppearanceUpdate()
    }
}

class ScreenBrightnessController: ObservableObject {
    
    // Current brightness state
    @Published var isScreenDimmed: Bool = false
    
    // Store original brightness value
    private var originalBrightness: CGFloat = 1.0
    
    // Brightness values
    private let dimmedBrightness: CGFloat = 0.0  // Absolute minimum brightness (0% = completely off)
    
    // Initialization
    init() {
        // Initialize with current screen brightness
        originalBrightness = UIScreen.main.brightness
    }
    
    /// Initialize brightness controller and save current brightness level
    /// Call this when the view appears
    func initialize() {
        originalBrightness = UIScreen.main.brightness
        isScreenDimmed = false
    }
    
    /// Toggle screen brightness between normal and dimmed (off)
    /// Announces state using Text-to-Speech
    func toggleBrightness() {
        if isScreenDimmed {
            // Turn screen on (restore brightness)
            turnOn()
        } else {
            // Turn screen off (dim to minimum)
            turnOff()
        }
    }
    
    /// Turn screen on by restoring original brightness
    /// Announces "Screen on" using Text-to-Speech
    func turnOn() {
        // Force brightness to restore with multiple attempts
        forceBrightness(originalBrightness)
        isScreenDimmed = false
        
        // Show status bar
        showStatusBar()
        
        // Announce state using Text-to-Speech
        TextToSpeech.shared.speak("Screen on", priority: .normal)
    }
    
    /// Turn screen off by setting brightness to absolute minimum
    /// Announces "Screen off" using Text-to-Speech
    func turnOff() {
        // Save current brightness before dimming (in case it changed)
        originalBrightness = UIScreen.main.brightness
        
        // Force brightness to absolute minimum with multiple attempts
        forceBrightness(0.0)
        isScreenDimmed = true
        
        // Hide status bar
        hideStatusBar()
        
        // Announce state using Text-to-Speech
        TextToSpeech.shared.speak("Screen off", priority: .normal)
    }
    
    /// Hide status bar for completely dark screen
    /// Uses a static variable that StatusBarController reads
    private func hideStatusBar() {
        DispatchQueue.main.async {
            StatusBarController.isStatusBarHidden = true
            // Notify all StatusBarController instances to update
            NotificationCenter.default.post(name: .statusBarVisibilityChanged, object: nil, userInfo: ["hidden": true])
        }
    }
    
    /// Show status bar
    /// Uses a static variable that StatusBarController reads
    private func showStatusBar() {
        DispatchQueue.main.async {
            StatusBarController.isStatusBarHidden = false
            // Notify all StatusBarController instances to update
            NotificationCenter.default.post(name: .statusBarVisibilityChanged, object: nil, userInfo: ["hidden": false])
        }
    }
    
    /// Force brightness to a specific value with multiple attempts
    /// This helps overcome iOS system limits that sometimes ignore single attempts
    private func forceBrightness(_ brightness: CGFloat) {
        // Set immediately
        UIScreen.main.brightness = brightness
        
        // Force multiple times with delays to ensure it sticks
        // iOS sometimes ignores the first attempt, especially when changing rapidly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UIScreen.main.brightness = brightness
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIScreen.main.brightness = brightness
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            UIScreen.main.brightness = brightness
        }
    }
    
    /// Restore original brightness and status bar
    /// Call this when the view disappears to restore system brightness
    func restoreBrightness() {
        if isScreenDimmed {
            forceBrightness(originalBrightness)
            isScreenDimmed = false
            // Show status bar when restoring
            showStatusBar()
        }
    }
    
    /// Get current brightness level (0.0 to 1.0)
    var currentBrightness: CGFloat {
        return UIScreen.main.brightness
    }
    
    /// Check if screen is currently dimmed
    var isDimmed: Bool {
        return isScreenDimmed
    }
}

