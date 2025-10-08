/*
PointCloudDepthSample.swift

Abstract:
The single entry point for the Scene Depth Point Cloud app.
*/

import SwiftUI
@main
struct PointCloudDepthSample: App {
    var body: some Scene {
        WindowGroup {
            MetalDepthView()
        }
    }
}
