import Testing
@testable import ScrolodexCore

@Suite("Trigger release behavior")
struct TriggerReleaseBehaviorTests {
    @Test("release confirms when a navigation session is active")
    func releaseConfirmsActiveSession() {
        #expect(TriggerReleaseBehavior.action(hasActiveSession: true) == .confirm)
    }

    @Test("release does nothing when no navigation session is active")
    func releaseDoesNothingWithoutSession() {
        #expect(TriggerReleaseBehavior.action(hasActiveSession: false) == .none)
    }
}
