import DesignSystem
import MoviesDomain
import SwiftUI

struct FeaturedCarousel: View {
    let movies: [Movie]
    let backdropURL: (Movie) -> URL?
    let onSelect: (Movie) -> Void

    @State private var selection = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                FeaturedSlide(movie: movie, url: backdropURL(movie)) { onSelect(movie) }
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 240)
        .padding(.bottom, 12)
        // Auto-advance every few seconds; off under Reduce Motion or with one slide.
        .task(id: movies.count) {
            guard !reduceMotion, movies.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                withAnimation(.smooth(duration: 0.6)) {
                    selection = (selection + 1) % movies.count
                }
            }
        }
        .accessibilityIdentifier("movie_list.featured_carousel")
    }
}

private struct FeaturedSlide: View {
    let movie: Movie
    let url: URL?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            RemoteImage(url: url)
                .overlay {
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(movie.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 8) {
                            if movie.voteCount > 0 {
                                RatingBadge(voteAverage: movie.voteAverage)
                            }
                            if let year = movie.releaseDate {
                                Text(year, format: .dateTime.year())
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .clipShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(movie.title))
        .accessibilityAddTraits(.isButton)
    }
}
