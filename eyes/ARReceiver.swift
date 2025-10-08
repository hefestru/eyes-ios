/*
ARReceiver.swift

Abstract:
A utility class that receives processed depth information.
*/

import Foundation
import SwiftUI
import Combine
import ARKit

// Receive the newest AR data from an `ARReceiver`.
protocol ARDataReceiver: AnyObject {
    func onNewARData(arData: ARData)
}

// Store depth-related AR data.
final class ARData {
    var depthImage: CVPixelBuffer?
    var depthSmoothImage: CVPixelBuffer?
    var colorImage: CVPixelBuffer?
    var confidenceImage: CVPixelBuffer?
    var confidenceSmoothImage: CVPixelBuffer?
    var cameraIntrinsics = simd_float3x3()
    var cameraResolution = CGSize()
}

// Configure and run an AR session to provide the app with depth-related AR data.
final class ARReceiver: NSObject, ARSessionDelegate {
    var arData = ARData()
    var arSession = ARSession()
    weak var delegate: ARDataReceiver?
    
    // Configure and start the ARSession.
    override init() {
        super.init()
        arSession.delegate = self
        // Do not start automatically to avoid capture errors
    }
    
    // Configure the ARKit session.
    func start() {
        guard ARWorldTrackingConfiguration.supportsFrameSemantics([.sceneDepth, .smoothedSceneDepth]) else { 
            return 
        }
        
        // Configure ARKit with improved error handling
        let config = ARWorldTrackingConfiguration()
        config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        
        // Additional configurations to improve stability
        config.isAutoFocusEnabled = true
        config.isLightEstimationEnabled = true
        
        arSession.run(config)
    }
    
    func pause() {
        arSession.pause()
    }
    
    // ARSession error handling
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Try to restart session after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.start()
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Session was interrupted
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        start()
    }
  
    // Send required data from `ARFrame` to the delegate class via the `onNewARData` callback.
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Verify that depth data is available
        guard let sceneDepth = frame.sceneDepth,
              let smoothedSceneDepth = frame.smoothedSceneDepth else {
            return
        }
        
        // Update data more safely
        arData.depthImage = sceneDepth.depthMap
        arData.depthSmoothImage = smoothedSceneDepth.depthMap
        arData.confidenceImage = sceneDepth.confidenceMap
        arData.confidenceSmoothImage = smoothedSceneDepth.confidenceMap
        arData.colorImage = frame.capturedImage
        arData.cameraIntrinsics = frame.camera.intrinsics
        arData.cameraResolution = frame.camera.imageResolution
        
        // Notify delegate asynchronously to avoid blocking
        DispatchQueue.main.async {
            self.delegate?.onNewARData(arData: self.arData)
        }
    }
}
