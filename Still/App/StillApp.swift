import StillKit
import SwiftUI

@main
struct StillApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(model.entitlements)
                .environment(model.clock)
                .task {
                    model.entitlements.start()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.becameActive()
            }
        }
    }
}
