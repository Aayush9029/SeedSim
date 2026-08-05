// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SeedSim",
    platforms: [
        .macOS(.v26),
    ],
    targets: [
        .target(
            name: "CLVGL",
            path: "Sources/CLVGL",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("lvgl"),
                .define("LV_CONF_INCLUDE_SIMPLE"),
                .unsafeFlags(["-Wno-unused-function", "-Wno-unused-but-set-variable"]),
            ]
        ),
        .executableTarget(
            name: "SeedSim",
            dependencies: ["CLVGL"],
            path: "Sources/SeedSim",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
