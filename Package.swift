// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "mouse-click-sound",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MouseClickSound", targets: ["MouseClickSound"])],
    targets: [
        .executableTarget(name: "MouseClickSound", exclude: ["Resources"])
    ]
)
