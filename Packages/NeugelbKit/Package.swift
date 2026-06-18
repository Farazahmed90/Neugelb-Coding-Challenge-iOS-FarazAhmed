// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NeugelbKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        // Reusable, app-agnostic foundation. Feature screens + view models
        // live in the app target and build on top of these.
        .library(name: "MoviesDomain", targets: ["MoviesDomain"]),
        .library(name: "MoviesData", targets: ["MoviesData"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        // Shared test factories and mocks, used by the package tests and the
        // app's test target so doubles are defined once.
        .library(name: "TestSupport", targets: ["TestSupport"]),
    ],
    targets: [
        .target(name: "MoviesDomain"),
        .target(
            name: "MoviesData",
            dependencies: ["MoviesDomain"]
        ),
        .target(
            name: "DesignSystem",
            resources: [.process("Resources")]
        ),
        .target(
            name: "TestSupport",
            dependencies: ["MoviesDomain", "MoviesData"]
        ),
        .testTarget(
            name: "MoviesDomainTests",
            dependencies: ["MoviesDomain", "TestSupport"]
        ),
        .testTarget(
            name: "MoviesDataTests",
            dependencies: ["MoviesData", "TestSupport"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
