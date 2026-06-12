// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NeugelbKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "MoviesDomain", targets: ["MoviesDomain"]),
        .library(name: "MoviesData", targets: ["MoviesData"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    targets: [
        .target(name: "MoviesDomain"),
        .target(
            name: "MoviesData",
            dependencies: ["MoviesDomain"]
        ),
        .target(name: "DesignSystem"),
        .testTarget(name: "MoviesDomainTests", dependencies: ["MoviesDomain"]),
        .testTarget(
            name: "MoviesDataTests",
            dependencies: ["MoviesData"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
