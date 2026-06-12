/// One page of a paginated collection.
public struct Page<Item: Sendable & Hashable>: Sendable, Hashable {
    public let items: [Item]
    public let pageNumber: Int
    public let totalPages: Int

    public var hasMore: Bool { pageNumber < totalPages }

    public init(items: [Item], pageNumber: Int, totalPages: Int) {
        self.items = items
        self.pageNumber = pageNumber
        self.totalPages = totalPages
    }
}
