// swift-tools-version: 6.0
import PackageDescription

// StillKit is shared by the app and every extension.
//
// - StillCore: pure Foundation logic (sessions, stats, schedules, storage).
//   It has no Apple-only imports, so its tests also run on Linux.
// - StillKit: the Screen Time (FamilyControls, ManagedSettings, DeviceActivity)
//   and ActivityKit glue used by the app and the extensions.
// - DesignSystem: color tokens, typography, spacing and reusable SwiftUI components.
let package = Package(
    name: "StillKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "StillCore", targets: ["StillCore"]),
        .library(name: "StillKit", targets: ["StillKit"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    targets: [
        .target(name: "StillCore"),
        .target(name: "StillKit", dependencies: ["StillCore"]),
        .target(name: "DesignSystem", dependencies: ["StillCore"]),
        .testTarget(name: "StillCoreTests", dependencies: ["StillCore"]),
    ],
    swiftLanguageModes: [.v6]
)
