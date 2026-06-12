import MoviesDomain
import Testing

struct PageTests {
    @Test func hasMoreWhenFurtherPagesExist() {
        let page = Page(items: [1, 2, 3], pageNumber: 1, totalPages: 5)
        #expect(page.hasMore)
    }

    @Test func hasNoMoreOnLastPage() {
        let page = Page(items: [1], pageNumber: 5, totalPages: 5)
        #expect(!page.hasMore)
    }

    @Test func hasNoMoreWhenEmptyResultSet() {
        let page = Page(items: [Int](), pageNumber: 1, totalPages: 0)
        #expect(!page.hasMore)
    }
}
