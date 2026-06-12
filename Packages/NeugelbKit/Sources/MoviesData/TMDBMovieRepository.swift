import Foundation
import MoviesDomain

/// `MovieRepository` backed by the TMDB REST API.
public struct TMDBMovieRepository: MovieRepository {
    private let client: TMDBAPIClient

    public init(client: TMDBAPIClient) {
        self.client = client
    }

    public func latestMovies(page: Int) async throws -> Page<Movie> {
        let dto: PageDTO<MovieDTO> = try await client.request(.nowPlaying(page: page))
        return dto.toDomain()
    }

    public func movieDetails(id: Movie.ID) async throws -> MovieDetails {
        let dto: MovieDetailsDTO = try await client.request(.movieDetails(id: id))
        return dto.toDomain()
    }

    public func searchMovies(matching query: String, page: Int) async throws -> Page<Movie> {
        let dto: PageDTO<MovieDTO> = try await client.request(
            .searchMovies(query: query, page: page)
        )
        return dto.toDomain()
    }
}
