import Testing
@testable import ScrolodexCore

@Suite("Overlay transition")
struct OverlayTransitionTests {
    @Test("list transition starts next selection from below for forward movement")
    func listForwardOffset() {
        #expect(OverlayTransition.initialOffset(for: 1, axis: .vertical) == -1)
    }

    @Test("tile transition starts next selection from the right for forward movement")
    func tileForwardOffset() {
        #expect(OverlayTransition.initialOffset(for: 1, axis: .horizontal) == 1)
    }

    @Test("zero movement has no transition offset")
    func zeroMovementOffset() {
        #expect(OverlayTransition.initialOffset(for: 0, axis: .vertical) == 0)
        #expect(OverlayTransition.initialOffset(for: 0, axis: .horizontal) == 0)
    }
}
