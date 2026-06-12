// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NeugelbKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "MoviesDomain", targets: ["MoviesDomain"]),
    ],
    targets: [
        .target(name: "MoviesDomain"),
        .testTarget(name: "MoviesDomainTests", dependencies: ["MoviesDomain"]),
    ]
)
