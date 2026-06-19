import DesignSystem
import MoviesDomain
import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    let posterURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            poster

            Text(movie.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(movie.title))
        .accessibilityValue(accessibilityDetails)
        .accessibilityIdentifier("movie_list.card.\(movie.id)")
    }

    private var poster: some View {
        RemoteImage(url: posterURL)
            .aspectRatio(2 / 3, contentMode: .fit)
            .overlay(alignment: .bottom) {
                // Scrim only behind the year chip so posters stay vivid.
                if releaseYear != nil {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
            }
            .overlay(alignment: .topTrailing) {
                if movie.voteCount > 0 {
                    RatingBadge(voteAverage: movie.voteAverage)
                        .padding(8)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if let year = releaseYear {
                    Text(year)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                }
            }
            .clipShape(.rect(cornerRadius: 16))
    }

    private var releaseYear: String? {
        movie.releaseDate.map { $0.formatted(.dateTime.year()) }
    }

    private var accessibilityDetails: Text {
        var parts: [String] = []
        if let releaseYear {
            parts.append(releaseYear)
        }
        if movie.voteCount > 0 {
            let rating = movie.voteAverage.formatted(.number.precision(.fractionLength(1)))
            parts.append(String(localized: "Rated \(rating) out of 10"))
        }
        return Text(parts.joined(separator: ", "))
    }

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

#if DEBUG
#Preview("Card") {
    MovieCardView(movie: PreviewData.movies[0], posterURL: nil)
        .frame(width: 180)
        .padding()
}

#Preview("Skeleton") {
    MovieCardView.skeleton
        .frame(width: 180)
        .padding()
}
#endif
