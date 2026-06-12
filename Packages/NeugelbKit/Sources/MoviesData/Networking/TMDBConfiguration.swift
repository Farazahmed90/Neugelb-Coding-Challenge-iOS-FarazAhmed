import Foundation

/// Environment for the TMDB API. Centralizes the base URLs and the
/// content language so they are injected, never hard-coded at call sites.
public struct TMDBConfiguration: Sendable {
    public let apiBaseURL: URL
    public let imageBaseURL: URL
    /// BCP-47 tag sent as TMDB's `language` query parameter so titles and
    /// overviews come back localized (falls back server-side to English).
    public let language: String

    public init(apiBaseURL: URL, imageBaseURL: URL, language: String) {
        self.apiBaseURL = apiBaseURL
        self.imageBaseURL = imageBaseURL
        self.language = language
    }

    public static func production(locale: Locale = .current) -> TMDBConfiguration {
        TMDBConfiguration(
            apiBaseURL: URL(string: "https://api.themoviedb.org/3")!,
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
            language: locale.identifier(.bcp47)
        )
    }
}
