import SwiftUI
import UIKit

enum ImageLoadingError: Error {
    case invalidImageData
}

/// Loads and caches remote images.
public protocol ImageLoading: Sendable {
    func image(for url: URL) async throws -> UIImage
}

/// Two-tier cache: decoded `UIImage`s in an `NSCache`, raw responses in
/// `URLCache` on disk. In-flight requests are de-duplicated so a grid
/// showing the same poster twice fetches it once.
public actor ImageLoader: ImageLoading {
    private let cache = NSCache<NSURL, UIImage>()
    private var inFlight: [URL: Task<UIImage, any Error>] = [:]
    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
        cache.totalCostLimit = 64 * 1024 * 1024
    }

    public func image(for url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        if let pending = inFlight[url] {
            return try await pending.value
        }

        let task = Task { [session] in
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                throw ImageLoadingError.invalidImageData
            }
            // Decode off the main thread so scrolling never pays for it.
            return await image.byPreparingForDisplay() ?? image
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let image = try await task.value
        cache.setObject(image, forKey: url as NSURL, cost: imageCost(image))
        return image
    }

    private func imageCost(_ image: UIImage) -> Int {
        Int(image.size.width * image.size.height * image.scale * image.scale) * 4
    }
}

public extension EnvironmentValues {
    @Entry var imageLoader: any ImageLoading = ImageLoader()
}
