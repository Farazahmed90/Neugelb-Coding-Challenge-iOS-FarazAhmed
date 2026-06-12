import Foundation
import MoviesDomain

/// `MovieRepository` backed by the TMDB REST API.
public struct TMDBMovieRepository: MovieRepository {
    private let client: TMDBAPIClient

    public init(client: TMDBAPIClient) {
        self.client = client
    }

    public func latestMovies(page: Int) async throws -> Page<Movie> {
        try await mappingErrors {
            let dto: PageDTO<MovieDTO> = try await client.request(.nowPlaying(page: page))
            return dto.toDomain()
        }
    }

    public func movieDetails(id: Movie.ID) async throws -> MovieDetails {
        try await mappingErrors {
            let dto: MovieDetailsDTO = try await client.request(.movieDetails(id: id))
            return dto.toDomain()
        }
    }

    public func searchMovies(matching query: String, page: Int) async throws -> Page<Movie> {
        try await mappingErrors {
            let dto: PageDTO<MovieDTO> = try await client.request(
                .searchMovies(query: query, page: page)
            )
            return dto.toDomain()
        }
    }

    /// Translates transport-level failures into the domain vocabulary.
    /// Cancellation passes through untouched so callers can ignore it.
    private func mappingErrors<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as APIError {
            throw MovieRepositoryError(mapping: error)
        }
    }
}

private extension MovieRepositoryError {
    init(mapping apiError: APIError) {
        switch apiError {
        case .transport:
            self = .network
        case .missingCredentials, .unacceptableStatus(401), .unacceptableStatus(403):
            self = .unauthorized
        case .unacceptableStatus(404):
            self = .notFound
        case .unacceptableStatus(let code) where code >= 500:
            self = .serverUnavailable
        case .unacceptableStatus, .invalidResponse, .decoding:
            self = .unknown
        }
    }
}
