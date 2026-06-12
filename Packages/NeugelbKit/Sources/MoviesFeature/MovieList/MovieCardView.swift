import DesignSystem
import MoviesDomain
import SwiftUI

/// Poster card with title, release year, and rating.
struct MovieCardView: View {
    let movie: Movie
    let posterURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RemoteImage(url: posterURL)
                .aspectRatio(2 / 3, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(alignment: .topTrailing) {
                    if movie.voteCount > 0 {
                        RatingBadge(voteAverage: movie.voteAverage)
                            .padding(8)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(movie.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                if let year = releaseYear {
                    Text(year)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier("movie_list.card.\(movie.id)")
    }

    private var releaseYear: String? {
        movie.releaseDate.map { $0.formatted(.dateTime.year()) }
    }

    private var accessibilitySummary: Text {
        var summary = movie.title
        if let releaseYear {
            summary += ", \(releaseYear)"
        }
        if movie.voteCount > 0 {
            let rating = movie.voteAverage.formatted(.number.precision(.fractionLength(1)))
            summary += ", rated \(rating) out of 10"
        }
        return Text(summary)
    }

    /// Redacted shimmer stand-in shown while the first page loads.
    static var skeleton: some View {
        MovieCardView(
            movie: Movie(
                id: 0,
                title: "Placeholder Title",
                overview: "",
                posterPath: nil,
                backdropPath: nil,
                releaseDate: nil,
                voteAverage: 0,
                voteCount: 0
            ),
            posterURL: nil
        )
        .redacted(reason: .placeholder)
        .shimmering()
        .accessibilityHidden(true)
    }
}
