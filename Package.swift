// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ijustlikeordinary",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ijustlikeordinary",
            targets: ["ijustlikeordinary"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ijustlikeordinary",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("CoreGraphics"),
                .linkedFramework("IOKit"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "ijustlikeordinaryTests",
            dependencies: ["ijustlikeordinary"],
            path: "Tests"
        )
    ]
)
