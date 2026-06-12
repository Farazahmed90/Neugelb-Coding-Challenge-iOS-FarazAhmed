import DesignSystem
import Foundation
import MoviesData
import MoviesDomain

/// Composition root: the only place that knows concrete implementations.
/// Everything downstream receives protocols.
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
            movieRepository: TMDBMovieRepository(client: apiClient),
            imageURLResolver: TMDBImageURLResolver(configuration: configuration),
            tokenProvider: tokenProvider,
            imageLoader: ImageLoader()
        )
    }
}
