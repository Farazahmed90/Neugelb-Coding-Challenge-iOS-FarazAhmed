// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NeugelbKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "MoviesDomain", targets: ["MoviesDomain"]),
        .library(name: "MoviesData", targets: ["MoviesData"]),
    ],
    targets: [
        .target(name: "MoviesDomain"),
        .target(
            name: "MoviesData",
            dependencies: ["MoviesDomain"]
        ),
        .testTarget(name: "MoviesDomainTests", dependencies: ["MoviesDomain"]),
        .testTarget(
            name: "MoviesDataTests",
            dependencies: ["MoviesData"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
