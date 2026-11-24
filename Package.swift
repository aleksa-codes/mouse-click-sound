// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "mouse-click-sound",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "MouseClickSound", targets: ["MouseClickSound"])],
    targets: [
        .executableTarget(
            name: "MouseClickSound",
            exclude: ["Resources"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
