import DesignSystem
import MoviesDomain
import SwiftUI

struct MovieDetailScreen: View {
    @Environment(\.openURL) private var openURL
    private let viewModel: MovieDetailViewModel
    @State private var overviewExpanded = false

    init(viewModel: MovieDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                content
                    .padding(20)
                    // Cap the text width on large screens and keep it centered.
                    .frame(maxWidth: 720, alignment: .leading)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIfNeeded() }
        .accessibilityIdentifier("movie_detail.screen")
    }

    // MARK: - Header

    private var header: some View {
        ParallaxHeader(height: 380) {
            RemoteImage(url: viewModel.backdropURL)
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.35), .clear, .clear, .black.opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .overlay(alignment: .bottomLeading) { heroOverlay }
    }

    private var heroOverlay: some View {
        HStack(alignment: .bottom, spacing: 16) {
            PosterCard(url: viewModel.posterURL)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.movie.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                if let tagline = viewModel.details?.tagline {
                    Text(tagline)
                        .font(.subheadline.italic())
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            detailBody(for: nil)
        case .loaded(let details):
            detailBody(for: details)
        case .failed(let message):
            ErrorStateView(message: message, retryTitle: String(localized: "Try Again")) {
                await viewModel.retry()
            }
            .padding(.top, 24)
        }
    }

    /// `nil` details shows redacted placeholders, so the layout doesn't jump once data loads.
    @ViewBuilder
    private func detailBody(for details: MovieDetails?) -> some View {
        let isPlaceholder = details == nil

        VStack(alignment: .leading, spacing: 28) {
            metaRow(for: details)

            if let trailerURL = viewModel.trailerURL {
                trailerButton(url: trailerURL)
            }

            if let genres = details?.genres, !genres.isEmpty {
                genreChips(genres)
            } else if isPlaceholder {
                genreChips([Genre(id: -1, name: "Placeholder"), Genre(id: -2, name: "Genre")])
            }

            overviewSection(for: details)

            castSection(for: details)

            factsSection(for: details)
        }
        .redacted(reason: isPlaceholder ? .placeholder : [])
        .shimmeringIf(isPlaceholder)
    }

    // MARK: - Meta row

    private func metaRow(for details: MovieDetails?) -> some View {
        HStack(spacing: 10) {
            if viewModel.movie.voteCount > 0 {
                RatingBadge(voteAverage: viewModel.movie.voteAverage)
                Text(votes(viewModel.movie.voteCount))
                    .foregroundStyle(.secondary)
            }
            if let year = viewModel.movie.releaseDate {
                Dot()
                Text(year, format: .dateTime.year())
            }
            if let runtime = details?.runtimeMinutes {
                Dot()
                Text(formattedRuntime(minutes: runtime))
                    .accessibilityLabel(Text("Runtime \(formattedRuntime(minutes: runtime))"))
            } else if details == nil {
                Dot()
                Text(verbatim: "0h 00m")
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.primary)
    }

    private func trailerButton(url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            Label(String(localized: L10n.MovieDetail.watchTrailer), systemImage: "play.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .accessibilityIdentifier("movie_detail.trailer_button")
    }

    private func genreChips(_ genres: [Genre]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(genres) { genre in
                    Text(genre.name)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(.tint.opacity(0.12), in: .capsule)
                        .foregroundStyle(.tint)
                }
            }
        }
        .scrollClipDisabled()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Overview

    @ViewBuilder
    private func overviewSection(for details: MovieDetails?) -> some View {
        let overview = details?.overview ?? viewModel.movie.overview

        if details == nil || !overview.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(Text(L10n.MovieDetail.overview))
                // Real words so the placeholder wraps like normal text.
                Text(overview.isEmpty ? Self.overviewPlaceholder : overview)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(overviewExpanded ? nil : 6)
                    .animation(.easeInOut(duration: 0.2), value: overviewExpanded)
                    .accessibilityIdentifier("movie_detail.overview")

                if details != nil, overview.count > 280 {
                    Button {
                        withAnimation { overviewExpanded.toggle() }
                    } label: {
                        Text(overviewExpanded ? L10n.MovieDetail.showLess : L10n.MovieDetail.showMore)
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                }
            }
        } else {
            Text(L10n.MovieDetail.noOverview)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Cast

    @ViewBuilder
    private func castSection(for details: MovieDetails?) -> some View {
        let cast = details?.cast ?? Self.placeholderCast
        if !cast.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(Text(L10n.MovieDetail.castSection))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(cast) { member in
                            CastCard(
                                name: member.name,
                                character: member.character,
                                imageURL: viewModel.profileURL(for: member)
                            )
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }

    // MARK: - Facts

    @ViewBuilder
    private func factsSection(for details: MovieDetails?) -> some View {
        let rows = details.map(factRows(for:)) ?? Self.placeholderFacts
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(Text(L10n.MovieDetail.detailsSection))
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        if index > 0 { Divider() }
                        HStack(alignment: .firstTextBaseline) {
                            Text(row.label)
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 16)
                            Text(row.value)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.subheadline)
                        .padding(.vertical, 11)
                    }
                }
                .padding(.horizontal, 16)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))
            }
        }
    }

    private func factRows(for details: MovieDetails) -> [(label: String, value: String)] {
        var rows: [(String, String)] = []
        if let status = details.status {
            rows.append((String(localized: L10n.MovieDetail.factStatus), status))
        }
        if let language = languageName(details.originalLanguage) {
            rows.append((String(localized: L10n.MovieDetail.factLanguage), language))
        }
        if let date = details.releaseDate {
            rows.append((
                String(localized: L10n.MovieDetail.factReleaseDate),
                date.formatted(.dateTime.day().month(.wide).year())
            ))
        }
        if let runtime = details.runtimeMinutes {
            rows.append((String(localized: L10n.MovieDetail.factRuntime), formattedRuntime(minutes: runtime)))
        }
        if let budget = details.budget {
            rows.append((String(localized: L10n.MovieDetail.factBudget), currency(budget)))
        }
        if let revenue = details.revenue {
            rows.append((String(localized: L10n.MovieDetail.factRevenue), currency(revenue)))
        }
        if !details.productionCompanies.isEmpty {
            rows.append((
                String(localized: L10n.MovieDetail.factStudio),
                details.productionCompanies.joined(separator: ", ")
            ))
        }
        return rows
    }

    // MARK: - Formatting

    private static let overviewPlaceholder = String(repeating: "Loading the movie overview text. ", count: 8)

    private static let placeholderCast: [CastMember] = (0..<4).map {
        CastMember(id: -$0 - 1, name: "Actor Name", character: "Character", profilePath: nil)
    }

    private static let placeholderFacts: [(label: String, value: String)] = [
        ("Status", "Released"), ("Language", "English"), ("Runtime", "2h 22m"),
    ]

    private func formattedRuntime(minutes: Int) -> String {
        Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    private func currency(_ amount: Int) -> String {
        // TMDB reports budget/revenue in USD.
        amount.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func votes(_ count: Int) -> String {
        count.formatted(.number.notation(.compactName))
    }

    private func languageName(_ code: String?) -> String? {
        guard let code else { return nil }
        return Locale.current.localizedString(forLanguageCode: code)?.capitalized ?? code.uppercased()
    }
}

// MARK: - Building blocks

/// A backdrop that stretches as the user pulls the scroll view past the top.
private struct ParallaxHeader<Content: View>: View {
    let height: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .global).minY
            let stretch = max(0, minY)
            content
                .frame(width: proxy.size.width, height: height + stretch)
                .offset(y: -stretch)
                .clipped()
        }
        .frame(height: height)
    }
}

private struct PosterCard: View {
    let url: URL?

    var body: some View {
        RemoteImage(url: url, placeholderSystemImage: "film")
            .frame(width: 104, height: 156)
            .clipShape(.rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }
}

private struct CastCard: View {
    let name: String
    let character: String?
    let imageURL: URL?

    var body: some View {
        VStack(spacing: 8) {
            RemoteImage(url: imageURL, placeholderSystemImage: "person.fill")
                .frame(width: 78, height: 78)
                .clipShape(.circle)
                .overlay { Circle().strokeBorder(.white.opacity(0.08)) }
            VStack(spacing: 2) {
                Text(name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                if let character {
                    Text(character)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .multilineTextAlignment(.center)
        }
        .frame(width: 92)
        .accessibilityElement(children: .combine)
    }
}

private struct SectionHeader: View {
    let title: Text
    init(_ title: Text) { self.title = title }

    var body: some View {
        title
            .font(.title3.weight(.bold))
            .accessibilityAddTraits(.isHeader)
    }
}

/// A small interpunct separator between metadata items.
private struct Dot: View {
    var body: some View {
        Text(verbatim: "·").foregroundStyle(.secondary)
    }
}

private extension View {
    @ViewBuilder
    func shimmeringIf(_ active: Bool) -> some View {
        if active { shimmering() } else { self }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack {
        MovieDetailScreen(
            viewModel: MovieDetailViewModel(
                movie: PreviewData.movies[0],
                repository: PreviewMovieRepository(),
                imageURLResolver: PreviewImageURLResolver()
            )
        )
    }
}

#Preview("Failure, Dark") {
    NavigationStack {
        MovieDetailScreen(
            viewModel: MovieDetailViewModel(
                movie: PreviewData.movies[1],
                repository: PreviewMovieRepository(failure: .network),
                imageURLResolver: PreviewImageURLResolver()
            )
        )
    }
    .preferredColorScheme(.dark)
}
#endif
