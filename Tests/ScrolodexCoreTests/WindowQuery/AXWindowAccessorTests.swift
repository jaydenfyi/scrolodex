import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("AX window accessor")
struct AXWindowAccessorTests {
    @Test("prefers exact CG window ID over ambiguous bounds")
    func prefersExactCGWindowID() {
        let candidate = WindowCandidate(
            cgWindowID: 1204,
            ownerPID: 693,
            ownerName: "Google Chrome",
            windowTitle: nil,
            bounds: CGRect(x: -190, y: -1094, width: 1920, height: 1040),
            layer: 0,
            alpha: 1
        )
        let snapshots = [
            AXWindowSnapshot(cgWindowID: 296, title: "YouTube", bounds: candidate.bounds),
            AXWindowSnapshot(cgWindowID: 1204, title: "Twitch", bounds: candidate.bounds),
            AXWindowSnapshot(cgWindowID: 931, title: "ChatGPT", bounds: candidate.bounds),
        ]

        #expect(AXWindowAccessor.bestWindowIndex(for: candidate, in: snapshots) == 1)
    }

    @Test("does not choose first window when bounds-only match is ambiguous")
    func rejectsAmbiguousBoundsOnlyMatch() {
        let candidate = WindowCandidate(
            cgWindowID: 1204,
            ownerPID: 693,
            ownerName: "Google Chrome",
            windowTitle: nil,
            bounds: CGRect(x: -190, y: -1094, width: 1920, height: 1040),
            layer: 0,
            alpha: 1
        )
        let snapshots = [
            AXWindowSnapshot(cgWindowID: nil, title: "YouTube", bounds: candidate.bounds),
            AXWindowSnapshot(cgWindowID: nil, title: "Twitch", bounds: candidate.bounds),
            AXWindowSnapshot(cgWindowID: nil, title: "ChatGPT", bounds: candidate.bounds),
        ]

        #expect(AXWindowAccessor.bestWindowIndex(for: candidate, in: snapshots) == nil)
    }
}
