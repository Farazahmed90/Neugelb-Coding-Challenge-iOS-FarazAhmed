import SwiftUI

/// `AsyncImage` replacement backed by the shared `ImageLoader` cache,
/// with a graceful placeholder for missing/failed images.
public struct RemoteImage: View {
    private let url: URL?
    private let placeholderSystemImage: String

    @Environment(\.imageLoader) private var imageLoader
    @State private var loadedImage: UIImage?

    public init(url: URL?, placeholderSystemImage: String = "film") {
        self.url = url
        self.placeholderSystemImage = placeholderSystemImage
    }

    public var body: some View {
        // Put the image in an overlay so scaledToFill doesn't grow the layout:
        // the view stays exactly the size its container offers.
        Color.clear
            .overlay {
                if let loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                } else {
                    placeholder
                }
            }
            .clipped()
            .task(id: url) {
                guard let url else {
                    loadedImage = nil
                    return
                }
                guard loadedImage == nil else { return }
                let image = try? await imageLoader.image(for: url)
                withAnimation(.easeIn(duration: 0.15)) {
                    loadedImage = image
                }
            }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                Image(systemName: placeholderSystemImage)
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
            }
    }
}
