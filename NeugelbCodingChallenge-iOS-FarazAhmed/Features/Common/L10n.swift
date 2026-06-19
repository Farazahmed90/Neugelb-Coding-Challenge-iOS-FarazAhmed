import Foundation

/// Typed, symbolic localization keys. Keeps the lookup key separate from the
/// English copy, so rewording source text doesn't orphan translations, and call
/// sites get autocomplete + compile-time safety.
enum L10n {
    enum Common {
        static let tryAgain = LocalizedStringResource(
            "common.try_again",
            defaultValue: "Try Again",
            comment: "Button title for the retry action."
        )
    }

    enum Grid {
        static let loading = LocalizedStringResource(
            "grid.loading",
            defaultValue: "Loading movies",
            comment: "Accessibility label for the loading skeleton grid."
        )
        static let loadingMore = LocalizedStringResource(
            "grid.loading_more",
            defaultValue: "Loading more movies",
            comment: "Accessibility label while the next page loads."
        )
        static let loadMoreFailed = LocalizedStringResource(
            "grid.load_more_failed",
            defaultValue: "Couldn't load more movies.",
            comment: "Shown when loading the next page fails."
        )
    }

    enum MovieList {
        static let title = LocalizedStringResource(
            "movie_list.title",
            defaultValue: "Now Playing",
            comment: "The title of the now-playing screen."
        )
        static let emptyTitle = LocalizedStringResource(
            "movie_list.empty_title",
            defaultValue: "No movies right now",
            comment: "A message that is displayed when there are no movies to show."
        )
        static let emptyDescription = LocalizedStringResource(
            "movie_list.empty_description",
            defaultValue: "Pull to refresh and check again.",
            comment: "A description of the action to take when the list is empty."
        )
    }

    enum MovieDetail {
        static let overview = LocalizedStringResource(
            "movie_detail.overview",
            defaultValue: "Overview",
            comment: "A label displayed above the movie's overview."
        )
        static let noOverview = LocalizedStringResource(
            "movie_detail.no_overview",
            defaultValue: "No overview available for this movie yet.",
            comment: "A message that indicates that there is no overview."
        )
        static let castSection = LocalizedStringResource(
            "movie_detail.cast_section",
            defaultValue: "Cast",
            comment: "Header above the cast carousel."
        )
        static let detailsSection = LocalizedStringResource(
            "movie_detail.details_section",
            defaultValue: "Details",
            comment: "Header above the facts grid."
        )
        static let watchTrailer = LocalizedStringResource(
            "movie_detail.watch_trailer",
            defaultValue: "Watch Trailer",
            comment: "Button that opens the movie trailer."
        )
        static let showMore = LocalizedStringResource(
            "movie_detail.show_more",
            defaultValue: "More",
            comment: "Expands the truncated overview."
        )
        static let showLess = LocalizedStringResource(
            "movie_detail.show_less",
            defaultValue: "Less",
            comment: "Collapses the expanded overview."
        )
        static let factStatus = LocalizedStringResource(
            "movie_detail.fact_status",
            defaultValue: "Status",
            comment: "Facts grid label: release status."
        )
        static let factLanguage = LocalizedStringResource(
            "movie_detail.fact_language",
            defaultValue: "Original Language",
            comment: "Facts grid label: original language."
        )
        static let factReleaseDate = LocalizedStringResource(
            "movie_detail.fact_release_date",
            defaultValue: "Release Date",
            comment: "Facts grid label: release date."
        )
        static let factRuntime = LocalizedStringResource(
            "movie_detail.fact_runtime",
            defaultValue: "Runtime",
            comment: "Facts grid label: runtime."
        )
        static let factBudget = LocalizedStringResource(
            "movie_detail.fact_budget",
            defaultValue: "Budget",
            comment: "Facts grid label: budget."
        )
        static let factRevenue = LocalizedStringResource(
            "movie_detail.fact_revenue",
            defaultValue: "Revenue",
            comment: "Facts grid label: revenue."
        )
        static let factStudio = LocalizedStringResource(
            "movie_detail.fact_studio",
            defaultValue: "Studio",
            comment: "Facts grid label: production companies."
        )
    }

    enum Search {
        static let prompt = LocalizedStringResource(
            "search.prompt",
            defaultValue: "Search movies",
            comment: "Placeholder in the search field."
        )
        static let suggestionsLabel = LocalizedStringResource(
            "search.suggestions_label",
            defaultValue: "Search suggestions",
            comment: "Accessibility label describing the search suggestions."
        )
        static let minCharacters = LocalizedStringResource(
            "search.min_characters",
            defaultValue: "Type at least two characters to search.",
            comment: "Hint shown in the search idle state."
        )
    }

    enum TokenEntry {
        static let title = LocalizedStringResource(
            "token_entry.title",
            defaultValue: "Welcome",
            comment: "Navigation title of the token entry screen."
        )
        static let accessTokenLabel = LocalizedStringResource(
            "token_entry.access_token_label",
            defaultValue: "TMDB Access Token",
            comment: "Field label / section header for the TMDB access token."
        )
        static let instructions = LocalizedStringResource(
            "token_entry.instructions",
            defaultValue: "Paste your TMDB API Read Access Token (v4) to load movies. It is stored securely in the Keychain. You can create a free token at themoviedb.org/settings/api.",
            comment: "Footer explaining how to obtain and store the token."
        )
        static let save = LocalizedStringResource(
            "token_entry.save",
            defaultValue: "Save",
            comment: "Button that saves the entered token."
        )
    }
}
