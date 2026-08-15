// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MicInputGuardian",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MicInputGuardian", targets: ["MicInputGuardian"])
    ],
    targets: [
        .executableTarget(
            name: "MicInputGuardian",
            path: "Sources/MicInputGuardian"
        ),
        .testTarget(
            name: "MicInputGuardianTests",
            dependencies: ["MicInputGuardian"]
        )
    ]
)
