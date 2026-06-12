import Foundation

/// Semantic image variants the UI can ask for, keeping provider-specific
/// size identifiers (e.g. TMDB's "w342") out of the feature layer.
public enum ImageKind: Sendable {
    case posterThumbnail
    case posterLarge
    case backdrop
}

/// Resolves a provider-relative image path into an absolute URL.
public protocol ImageURLResolving: Sendable {
    func imageURL(forPath path: String?, kind: ImageKind) -> URL?
}
