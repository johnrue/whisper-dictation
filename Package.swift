// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Whisper",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
        .package(url: "https://github.com/MrKai77/DynamicNotchKit.git", from: "1.1.0")
    ],
    targets: [
        .executableTarget(
            name: "Whisper",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "DynamicNotchKit", package: "DynamicNotchKit")
            ],
            path: "Sources/Whisper"
        )
    ]
)
