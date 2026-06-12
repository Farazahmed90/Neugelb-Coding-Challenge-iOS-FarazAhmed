import DesignSystem
import MoviesDomain
import SwiftUI

/// Movie details: backdrop header rendered instantly from list data,
/// with metadata and overview arriving as the full record loads.
public struct MovieDetailScreen: View {
    private let viewModel: MovieDetailViewModel

    public init(viewModel: MovieDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                content
                    .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIfNeeded() }
        .accessibilityIdentifier("movie_detail.screen")
    }

    // MARK: - Header

    private var header: some View {
        RemoteImage(url: viewModel.backdropURL)
            .aspectRatio(16 / 10, contentMode: .fit)
            .overlay {
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.movie.title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
                    if let tagline {
                        Text(tagline)
                            .font(.subheadline.italic())
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding()
            }
            .clipped()
    }

    // MARK: - Content states

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            detailBody(for: nil)
        case .loaded(let details):
            detailBody(for: details)
        case .failed(let message):
            ErrorStateView(
                message: message,
                retryTitle: String(localized: "Try Again", bundle: .module)
            ) {
                await viewModel.retry()
            }
            .padding(.top, 24)
        }
    }

    /// Renders the full layout; `nil` details means "still loading" and
    /// shows redacted placeholders so the page doesn't jump when data lands.
    @ViewBuilder
    private func detailBody(for details: MovieDetails?) -> some View {
        let isPlaceholder = details == nil

        VStack(alignment: .leading, spacing: 20) {
            metadataRow(for: details)

            if let genres = details?.genres, !genres.isEmpty {
                genreChips(genres)
            } else if isPlaceholder {
                genreChips([
                    Genre(id: -1, name: "Placeholder"),
                    Genre(id: -2, name: "Genre"),
                ])
            }

            overviewSection(for: details)
        }
        .redacted(reason: isPlaceholder ? .placeholder : [])
        .shimmeringIf(isPlaceholder)
    }

    private func metadataRow(for details: MovieDetails?) -> some View {
        HStack(spacing: 12) {
            if viewModel.movie.voteCount > 0 {
                RatingBadge(voteAverage: viewModel.movie.voteAverage)
            }
            if let releaseDate = viewModel.movie.releaseDate {
                Text(releaseDate, format: .dateTime.year())
            }
            if let runtime = details?.runtimeMinutes {
                Text(formattedRuntime(minutes: runtime))
                    .accessibilityLabel(
                        Text("Runtime \(formattedRuntime(minutes: runtime))", bundle: .module)
                    )
            } else if details == nil {
                Text(verbatim: "0h 00m")
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
    }

    private func genreChips(_ genres: [Genre]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(genres) { genre in
                    Text(genre.name)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.tint.opacity(0.12), in: .capsule)
                        .foregroundStyle(.tint)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func overviewSection(for details: MovieDetails?) -> some View {
        let overview = details?.overview ?? viewModel.movie.overview

        if details == nil || !overview.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Overview", bundle: .module)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(overview.isEmpty ? String(repeating: " ", count: 280) : overview)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("movie_detail.overview")
            }
        } else {
            Text("No overview available for this movie yet.", bundle: .module)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var tagline: String? {
        guard case .loaded(let details) = viewModel.state else { return nil }
        return details.tagline
    }

    private func formattedRuntime(minutes: Int) -> String {
        Duration.seconds(minutes * 60).formatted(
            .units(allowed: [.hours, .minutes], width: .narrow)
        )
    }
}

private extension View {
    @ViewBuilder
    func shimmeringIf(_ active: Bool) -> some View {
        if active {
            shimmering()
        } else {
            self
        }
    }
}
