// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TodoSticky",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "TodoSticky",
            path: "Sources/TodoSticky"
        )
    ]
)
