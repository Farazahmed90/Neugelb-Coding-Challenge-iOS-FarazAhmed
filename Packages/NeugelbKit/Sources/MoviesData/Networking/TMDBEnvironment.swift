import Foundation

// We can move this to Info.plist/xcconfig if we ever need separate dev/prod URLs.
enum TMDBEnvironment {
    static let apiBaseURL = URL(string: "https://api.themoviedb.org/3")!
    static let imageBaseURL = URL(string: "https://image.tmdb.org/t/p")!
}
