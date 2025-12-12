import Testing

@testable import PaulBunyan

@Test func `Rotator@sortedItems sorts`() async throws {
    #expect(Rotator(["a", "b", "c"], keeping: 1).sortedItems == ["a", "b", "c"])
    #expect(
        Rotator(["2021-01-01", "2022-02-02", "2023-03-03"], keeping: 1).sortedItems == [
            "2021-01-01", "2022-02-02", "2023-03-03",
        ])
}

@Test func `Rotator@itemsToDelete keeps all items`() async throws {
    #expect(Rotator(["a", "b", "c"], keeping: 3).itemsToDelete == [])
    #expect(Rotator(["a", "b", "c"], keeping: 10).itemsToDelete == [])
}

@Test func `Rotator@itemsToDelete deletes oldest items`() async throws {
    #expect(Rotator(["a", "b", "c"], keeping: 1).itemsToDelete == ["a", "b"])
    #expect(Rotator(["a", "b", "c"], keeping: 2).itemsToDelete == ["a"])
}
