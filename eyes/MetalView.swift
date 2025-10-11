/*
MetalView.swift

Abstract:
A parent view class that displays the sample app's other views.
*/

import Foundation
import SwiftUI
import MetalKit
import ARKit

// ========================================
// COLLISION DETECTION CONFIGURATION
// ========================================
// CHANGE THIS VALUE TO ADJUST ALERT DISTANCE:
// 0.3 = 30cm, 0.5 = 50cm, 0.6 = 60cm, 0.8 = 80cm, 0.9 = 90cm
let COLLISION_DISTANCE_THRESHOLD: Float = 0.9

// Central detection strip configuration
let CENTRAL_STRIP_WIDTH_RATIO: Float = 0.3  // 30% of image width

// Add a title to a view that enlarges the view to full screen on tap.
struct Texture<T: View>: ViewModifier {
    let height: CGFloat
    let width: CGFloat
    let title: String
    let view: T
    func body(content: Content) -> some View {
        VStack {
            Text(title).foregroundColor(Color.red)
            // To display the same view in the navigation, reference the view
            // directly versus using the view's `content` property.
            NavigationLink(destination: view.aspectRatio(CGSize(width: width, height: height), contentMode: .fill)) {
                view.frame(maxWidth: width, maxHeight: height, alignment: .center)
                    .aspectRatio(CGSize(width: width, height: height), contentMode: .fill)
            }
        }
    }
}

extension View {
    // Apply `zoomOnTapModifier` with a `self` reference to show the same view
    // on tap.
    func zoomOnTapModifier(height: CGFloat, width: CGFloat, title: String) -> some View {
        modifier(Texture(height: height, width: width, title: title, view: self))
    }
}
extension Image {
    init(_ texture: MTLTexture, ciContext: CIContext, scale: CGFloat, orientation: Image.Orientation, label: Text) {
        let ciimage = CIImage(mtlTexture: texture)!
        let cgimage = ciContext.createCGImage(ciimage, from: ciimage.extent)
        self.init(cgimage!, scale: 1.0, orientation: orientation, label: label)
    }
}
struct MetalDepthView: View {
    
    // Manage the AR session and AR data processing.
    @StateObject private var arProvider = ARProvider()
    
    // Save the user's confidence selection.
    @State private var selectedConfidence = 0
    
    // View mode switching
    @State private var isDepthMode = true
    
    // ========================================
    // COLLISION DETECTION CONFIGURATION
    // ========================================
    // Distance is configured in COLLISION_DISTANCE_THRESHOLD constant at the beginning of the file
    @State private var collisionDistance: Float = COLLISION_DISTANCE_THRESHOLD
    @State private var isCollisionDetected = false
    @State private var collisionAlert = ""
    
    // ========================================
    // COLLISION DETECTION CONFIGURATION
    // ========================================
    @State private var collisionDetectionTimer: Timer?
    @State private var showDetectionStrip = true  // Show detection strip
    @State private var stripWidth: CGFloat = 0    // Strip width on screen
    @State private var stripStartX: CGFloat = 0   // X position of strip start
    
    var body: some View {
        if !ARWorldTrackingConfiguration.supportsFrameSemantics([.sceneDepth, .smoothedSceneDepth]) {
            Text("Incompatible device: This app requires LiDAR scanner to access scene depth.")
                .padding()
                .multilineTextAlignment(.center)
        } else {
            ZStack {
                // Main view (depth or camera)
                if isDepthMode {
                    MetalTextureViewDepth(content: arProvider.depthContent, confSelection: $selectedConfidence)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    // Normal camera view
                    MetalTextureViewCamera(content: arProvider.colorYContent)
                        .frame(maxWidth: CGFloat.greatestFiniteMagnitude, maxHeight: CGFloat.greatestFiniteMagnitude)
                        .clipped()
                }
                
                // Detection strip overlay
                if showDetectionStrip {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: stripWidth, height: geometry.size.height)
                            .position(x: stripStartX + stripWidth/2, y: geometry.size.height/2)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                    .frame(width: stripWidth, height: geometry.size.height)
                                    .position(x: stripStartX + stripWidth/2, y: geometry.size.height/2)
                            )
                    }
                }
                
                // Collision alert overlay
                if isCollisionDetected {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                Text(collisionAlert)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(10)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .background(Color.black.opacity(0.3))
                }
                
                // Control buttons at the bottom
                VStack {
                    Spacer()
                    HStack {
                        // Button to toggle detection strip
                        Button(action: {
                            showDetectionStrip.toggle()
                        }) {
                            Image(systemName: showDetectionStrip ? "eye.slash" : "eye")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                                .frame(width: 50, height: 50)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        Spacer()
                        
                        // View mode toggle button
                        Button(action: {
                            isDepthMode.toggle()
                        }) {
                            Image(systemName: isDepthMode ? "camera" : "viewfinder")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .frame(width: 60, height: 60)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        Spacer()
                        
                        // Info button
                        Button(action: {
                            // Show information about detection strip
                        }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                                .frame(width: 50, height: 50)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
            }
            .ignoresSafeArea(.all)
            .onAppear {
                // Initialize ARKit more robustly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.arProvider.start()
                    self.startCollisionDetection()
                }
                // Keep screen on during use
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                stopCollisionDetection()
                // Pause AR session to free resources
                arProvider.pause()
                // Restore normal screen behavior
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }
    
    // Function to detect collisions based on depth data
    private func startCollisionDetection() {
        collisionDetectionTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            DispatchQueue.global(qos: .userInitiated).async {
                self.checkForCollisions()
            }
        }
    }
    
    private func stopCollisionDetection() {
        collisionDetectionTimer?.invalidate()
        collisionDetectionTimer = nil
    }
    
    private func checkForCollisions() {
        guard let depthData = arProvider.lastArData?.depthImage else { return }
        
        let width = CVPixelBufferGetWidth(depthData)
        let height = CVPixelBufferGetHeight(depthData)
        
        
        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        let depthPointer = CVPixelBufferGetBaseAddress(depthData)?.assumingMemoryBound(to: Float32.self)
        
        var closestDistance: Float = Float.greatestFiniteMagnitude
        var hasObstacleInRange = false
        
        // Calculate central vertical strip for phone in portrait
        // Depth data is in landscape (256x192), but phone is in portrait
        // We need to analyze a strip that corresponds to vertical phone orientation
        
        // If data is landscape (width > height), we need a vertical strip
        // that corresponds to portrait phone orientation
        let stripWidthPixels = Int(Float(width) * CENTRAL_STRIP_WIDTH_RATIO)
        let stripStartX = (width - stripWidthPixels) / 2
        // Calculate visual strip directly in screen coordinates
        let screenWidth = UIScreen.main.bounds.width
        
        // Map depth data strip directly to full screen
        let stripWidthScreen = screenWidth * CGFloat(CENTRAL_STRIP_WIDTH_RATIO)
        let stripStartXScreen = (screenWidth - stripWidthScreen) / 2
        
        // Update strip dimensions on screen
        DispatchQueue.main.async {
            self.stripWidth = stripWidthScreen
            self.stripStartX = stripStartXScreen
        }
        
        // Analyze strip that corresponds to VERTICAL phone orientation
        // If data is landscape (256x192) and phone is portrait, we need
        // to analyze a HORIZONTAL strip in the data to correspond to VERTICAL on the phone
        
        let stripHeightPixels = Int(Float(height) * CENTRAL_STRIP_WIDTH_RATIO)
        let stripStartY = (height - stripHeightPixels) / 2
        let stripEndY = stripStartY + stripHeightPixels
        
        
        for y in stripStartY..<stripEndY {
            for x in 0..<width {
                let index = y * width + x
                let depth = depthPointer?[index] ?? 0
                
                // Only consider valid distances within 90cm range
                if depth > 0 && depth < collisionDistance {
                    hasObstacleInRange = true
                    closestDistance = min(closestDistance, depth)
                }
            }
        }
        
        CVPixelBufferUnlockBaseAddress(depthData, .readOnly)
        
        // Update collision state
        DispatchQueue.main.async {
            if hasObstacleInRange {
                self.isCollisionDetected = true
                self.collisionAlert = "DANGER!\nObstacle at \(Int(closestDistance * 100))cm"
            } else {
                self.isCollisionDetected = false
                self.collisionAlert = ""
            }
        }
    }
    
}
struct MtkView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MetalDepthView().previewDevice("iPad Pro (12.9-inch) (4th generation)")
            MetalDepthView().previewDevice("iPhone 11 Pro")
        }
    }
}
