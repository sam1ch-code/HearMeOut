import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            CameraViewV1(cameraManager: CameraManager())
                .ignoresSafeArea()
        }
    }
}
