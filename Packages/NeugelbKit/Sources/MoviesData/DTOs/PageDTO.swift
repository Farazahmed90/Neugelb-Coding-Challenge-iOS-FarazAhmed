import Foundation
import MoviesDomain

/// Generic TMDB paged response. Mirrors the JSON after snake_case conversion and
/// stays internal to the data layer; the rest of the app sees domain types only.
struct PageDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    let page: Int
    let results: [Item]
    let totalPages: Int
}

extension PageDTO where Item == MovieDTO {
    func toDomain() -> Page<Movie> {
        Page(
            items: results.map { $0.toDomain() },
            pageNumber: page,
            totalPages: totalPages
        )
    }
}
