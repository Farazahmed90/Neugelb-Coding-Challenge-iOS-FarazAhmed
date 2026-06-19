import DesignSystem
import Foundation
import MoviesData
import MoviesDomain

/// Composition root — builds the concrete types and wires them together.
struct AppDependencies {
    let movieRepository: any MovieRepository
    let imageURLResolver: any ImageURLResolving
    let tokenProvider: TMDBAccessTokenProvider
    let imageLoader: any ImageLoading

    static func live() -> AppDependencies {
        let configuration = TMDBConfiguration.production()
        let tokenProvider = TMDBAccessTokenProvider(
            store: KeychainSecretStore(
                service: Bundle.main.bundleIdentifier ?? "com.neugelb.challenge"
            )
        )
        let apiClient = TMDBAPIClient(
            httpClient: URLSessionHTTPClient(),
            tokenProvider: tokenProvider,
            configuration: configuration
        )
        return AppDependencies(
            movieRepository: OfflineFallbackMovieRepository(
                remote: TMDBMovieRepository(client: apiClient),
                cache: MovieListDiskCache()
            ),
            imageURLResolver: TMDBImageURLResolver(configuration: configuration),
            tokenProvider: tokenProvider,
            imageLoader: ImageLoader()
        )
    }
}
