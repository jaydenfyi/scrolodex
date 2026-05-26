import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Navigation session")
struct NavigationSessionTests {
    @Test("accumulates deltas until threshold before changing selection")
    func accumulatesDeltasUntilThreshold() {
        var session = NavigationSession(candidates: candidates, scrollThreshold: 10)

        #expect(session.selectedCandidate.cgWindowID == 1)
        #expect(session.applyScrollDelta(4) == .none)
        #expect(session.selectedCandidate.cgWindowID == 1)
        #expect(session.applyScrollDelta(6) == .changed(direction: 1, wrapped: false))
        #expect(session.selectedCandidate.cgWindowID == 2)
    }

    @Test("sub-threshold scroll remains invisible to presentation")
    func subThresholdScrollRemainsInvisible() {
        var session = NavigationSession(candidates: candidates, scrollThreshold: 10)

        #expect(session.applyScrollDelta(4) == .none)
        #expect(session.applyScrollDelta(-3) == .none)
        #expect(session.selectedCandidate.cgWindowID == 1)
    }

    @Test("threshold crossings report movement direction")
    func thresholdCrossingsReportMovementDirection() {
        var session = NavigationSession(candidates: candidates, scrollThreshold: 10)

        #expect(session.applyScrollDelta(10) == .changed(direction: 1, wrapped: false))
        #expect(session.selectedCandidate.cgWindowID == 2)
        #expect(session.applyScrollDelta(-10) == .changed(direction: -1, wrapped: false))
        #expect(session.selectedCandidate.cgWindowID == 1)
    }

    @Test("wraps forward and backward through candidates")
    func wrapsSelection() {
        var session = NavigationSession(candidates: candidates, scrollThreshold: 1)

        _ = session.applyScrollDelta(1)
        _ = session.applyScrollDelta(1)
        #expect(session.applyScrollDelta(1) == .changed(direction: 1, wrapped: true))
        #expect(session.selectedCandidate.cgWindowID == 1)

        #expect(session.applyScrollDelta(-1) == .changed(direction: -1, wrapped: true))
        #expect(session.selectedCandidate.cgWindowID == 3)
    }

    @Test("step moves selection forward and backward")
    func stepMovesSelection() {
        var session = NavigationSession(candidates: candidates, scrollThreshold: 1)

        #expect(session.step(direction: 1) == .changed(direction: 1, wrapped: false))
        #expect(session.selectedCandidate.cgWindowID == 2)

        #expect(session.step(direction: -1) == .changed(direction: -1, wrapped: false))
        #expect(session.selectedCandidate.cgWindowID == 1)
    }

    @Test("step with zero direction returns none")
    func stepZeroDirection() {
        var session = NavigationSession(candidates: candidates, scrollThreshold: 1)
        #expect(session.step(direction: 0) == .none)
        #expect(session.selectedCandidate.cgWindowID == 1)
    }

    @Test("step wraps around")
    func stepWraps() {
        var session = NavigationSession(candidates: candidates, scrollThreshold: 1)

        #expect(session.step(direction: -1) == .changed(direction: -1, wrapped: true))
        #expect(session.selectedCandidate.cgWindowID == 3)
    }

    @Test("step stops at boundary when wrap around is disabled")
    func stepStopsAtBoundaryNoWrap() {
        var session = NavigationSession(candidates: candidates, scrollThreshold: 1, wrapAround: false)

        #expect(session.step(direction: -1) == .none)
        #expect(session.selectedCandidate.cgWindowID == 1)

        #expect(session.step(direction: 1) == .changed(direction: 1, wrapped: false))
        #expect(session.step(direction: 1) == .changed(direction: 1, wrapped: false))
        #expect(session.selectedCandidate.cgWindowID == 3)

        #expect(session.step(direction: 1) == .none)
        #expect(session.selectedCandidate.cgWindowID == 3)
    }

    @Test("scroll stops at boundary when wrap around is disabled")
    func scrollStopsAtBoundaryNoWrap() {
        var session = NavigationSession(candidates: candidates, scrollThreshold: 1, wrapAround: false)

        #expect(session.applyScrollDelta(-1) == .none)
        #expect(session.selectedCandidate.cgWindowID == 1)

        #expect(session.applyScrollDelta(1) == .changed(direction: 1, wrapped: false))
        #expect(session.applyScrollDelta(1) == .changed(direction: 1, wrapped: false))
        #expect(session.selectedCandidate.cgWindowID == 3)

        #expect(session.applyScrollDelta(1) == .none)
        #expect(session.selectedCandidate.cgWindowID == 3)
    }

    @Test("confirm ends session with terminal outcome")
    func confirmOutcome() {
        var confirmed = NavigationSession(candidates: candidates, scrollThreshold: 1)
        _ = confirmed.applyScrollDelta(1)
        let confirmedOutcome = confirmed.confirm()

        #expect(confirmedOutcome == .confirmed(candidates[1]))
        #expect(confirmed.isActive == false)
    }

    private var candidates: [WindowCandidate] {
        [
            WindowCandidate(cgWindowID: 1, ownerPID: 1, ownerName: "One", windowTitle: nil, bounds: .zero, layer: 0, alpha: 1),
            WindowCandidate(cgWindowID: 2, ownerPID: 2, ownerName: "Two", windowTitle: nil, bounds: .zero, layer: 0, alpha: 1),
            WindowCandidate(cgWindowID: 3, ownerPID: 3, ownerName: "Three", windowTitle: nil, bounds: .zero, layer: 0, alpha: 1)
        ]
    }
}
