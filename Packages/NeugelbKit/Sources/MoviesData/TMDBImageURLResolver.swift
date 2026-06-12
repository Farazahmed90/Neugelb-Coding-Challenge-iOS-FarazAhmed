import Foundation
import MoviesDomain

/// Maps semantic image kinds to TMDB's fixed-width rendition paths.
public struct TMDBImageURLResolver: ImageURLResolving {
    private let configuration: TMDBConfiguration

    public init(configuration: TMDBConfiguration) {
        self.configuration = configuration
    }

    public func imageURL(forPath path: String?, kind: ImageKind) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return configuration.imageBaseURL
            .appending(path: width(for: kind))
            .appending(path: path.trimmingPrefix("/"))
    }

    private func width(for kind: ImageKind) -> String {
        switch kind {
        case .posterThumbnail: return "w342"
        case .posterLarge: return "w780"
        case .backdrop: return "w1280"
        }
    }
}
