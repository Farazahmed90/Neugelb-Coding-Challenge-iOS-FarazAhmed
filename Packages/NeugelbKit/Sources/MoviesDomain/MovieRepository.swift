/// Abstraction over the movie catalog. Implemented by the data layer,
/// mocked in feature tests.
public protocol MovieRepository: Sendable {
    /// Movies currently playing in theaters, newest first, paginated.
    func latestMovies(page: Int) async throws -> Page<Movie>

    /// Full details for a single movie.
    func movieDetails(id: Movie.ID) async throws -> MovieDetails

    /// Movies matching a free-text query, paginated.
    func searchMovies(matching query: String, page: Int) async throws -> Page<Movie>
}
