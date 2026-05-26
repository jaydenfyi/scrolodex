import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Overlay anchor session")
struct OverlayAnchorSessionTests {
    @Test("keeps initial anchor while selection changes")
    func keepsInitialAnchor() {
        var session = OverlayAnchorSession()

        let first = CGPoint(x: 100, y: 200)
        let second = CGPoint(x: 900, y: 700)

        #expect(session.anchor(startingAt: first) == first)
        #expect(session.anchor(startingAt: second) == first)
    }

    @Test("reset allows next session to choose a new anchor")
    func resetAllowsNewAnchor() {
        var session = OverlayAnchorSession()

        _ = session.anchor(startingAt: CGPoint(x: 100, y: 200))
        session.reset()

        #expect(session.anchor(startingAt: CGPoint(x: 900, y: 700)) == CGPoint(x: 900, y: 700))
    }
}
