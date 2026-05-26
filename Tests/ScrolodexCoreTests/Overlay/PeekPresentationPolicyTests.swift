import Testing
@testable import ScrolodexCore

@Suite("Peek presentation policy")
struct PeekPresentationPolicyTests {
    @Test("under cursor initial selection uses border-only peek")
    func underCursorInitialSelectionUsesBorderOnly() {
        #expect(PeekPresentationPolicy.usesBorderOnly(scope: .underCursor, isInitialSelection: true))
    }

    @Test("current screen initial selection uses border-only peek")
    func currentScreenInitialSelectionUsesBorderOnly() {
        #expect(PeekPresentationPolicy.usesBorderOnly(scope: .currentScreen, isInitialSelection: true))
    }

    @Test("dock hover initial selection uses snapshot peek")
    func dockHoverInitialSelectionUsesSnapshot() {
        #expect(!PeekPresentationPolicy.usesBorderOnly(scope: .dockHover, isInitialSelection: true))
    }

    @Test("non-initial selections use snapshot peek")
    func nonInitialSelectionsUseSnapshot() {
        #expect(!PeekPresentationPolicy.usesBorderOnly(scope: .underCursor, isInitialSelection: false))
        #expect(!PeekPresentationPolicy.usesBorderOnly(scope: .currentScreen, isInitialSelection: false))
        #expect(!PeekPresentationPolicy.usesBorderOnly(scope: .dockHover, isInitialSelection: false))
    }
}
