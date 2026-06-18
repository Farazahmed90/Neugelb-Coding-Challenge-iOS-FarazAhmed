import Foundation
import MoviesData
import MoviesDomain

public struct ImageURLResolverStub: ImageURLResolving {
    public init() {}

    public func imageURL(forPath path: String?, kind: ImageKind) -> URL? {
        path.map { URL(string: "https://images.example.com/stub\($0)")! }
    }
}

/// In-memory `MovieListCaching`, records what was saved.
public actor CacheSpy: MovieListCaching {
    public private(set) var stored: Page<Movie>?

    public init(stored: Page<Movie>? = nil) {
        self.stored = stored
    }

    public func save(_ page: Page<Movie>) {
        stored = page
    }

    public func loadLatest() -> Page<Movie>? {
        stored
    }
}
