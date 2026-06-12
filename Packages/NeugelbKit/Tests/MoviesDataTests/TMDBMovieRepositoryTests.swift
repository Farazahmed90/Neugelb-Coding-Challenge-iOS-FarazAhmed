import Foundation
import MoviesData
import MoviesDomain
import Testing

struct TMDBMovieRepositoryTests {
    private func makeRepository(returning fixture: String) throws -> TMDBMovieRepository {
        let http = HTTPClientMock(
            .success(data: try Fixtures.data(fixture), statusCode: 200)
        )
        let client = TMDBAPIClient(
            httpClient: http, tokenProvider: StaticTokenProvider(), configuration: .test
        )
        return TMDBMovieRepository(client: client)
    }

    @Test func mapsNowPlayingPageToDomain() async throws {
        let repository = try makeRepository(returning: "now_playing")

        let page = try await repository.latestMovies(page: 1)

        #expect(page.pageNumber == 1)
        #expect(page.totalPages == 213)
        #expect(page.hasMore)
        #expect(page.items.count == 3)

        let first = try #require(page.items.first)
        #expect(first.id == 278)
        #expect(first.title == "The Shawshank Redemption")
        #expect(first.posterPath == "/9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg")
        #expect(first.voteAverage == 8.712)
        #expect(first.releaseDate != nil)
    }

    @Test func toleratesMissingOptionalFields() async throws {
        let repository = try makeRepository(returning: "now_playing")

        let page = try await repository.latestMovies(page: 1)
        let sparse = try #require(page.items.first { $0.id == 99999901 })

        // Null poster, empty release_date, and empty overview must map to
        // safe values instead of failing the whole page.
        #expect(sparse.posterPath == nil)
        #expect(sparse.backdropPath == nil)
        #expect(sparse.releaseDate == nil)
        #expect(sparse.overview.isEmpty)
    }

    @Test func mapsMovieDetailsToDomain() async throws {
        let repository = try makeRepository(returning: "movie_details")

        let details = try await repository.movieDetails(id: 278)

        #expect(details.id == 278)
        #expect(details.title == "The Shawshank Redemption")
        #expect(details.tagline == "Fear can hold you prisoner. Hope can set you free.")
        #expect(details.runtimeMinutes == 142)
        #expect(details.genres == [Genre(id: 18, name: "Drama"), Genre(id: 80, name: "Crime")])
    }

    @Test func mapsSearchResultsToDomain() async throws {
        let repository = try makeRepository(returning: "search_movies")

        let page = try await repository.searchMovies(matching: "fight", page: 1)

        #expect(page.items.map(\.id) == [550])
        #expect(!page.hasMore)
    }
}
