import Foundation

/// TMDB dates are "yyyy-MM-dd" strings and occasionally empty.
enum TMDBDateParser {
    private static let calendar = Calendar(identifier: .gregorian)

    static func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.timeZone = TimeZone(identifier: "UTC")
        return calendar.date(from: components)
    }
}
