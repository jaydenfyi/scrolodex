import Testing
@testable import ScrolodexCore

@Suite("Space switcher")
struct SpaceSwitcherTests {
    @Test("dock swipe payload uses nonzero float progress and mirrored velocity")
    func dockSwipePayloadUsesCommitFriendlyValues() {
        let payload = SpaceSwipePayload(phase: .changed, direction: .right, velocity: 600)

        #expect(payload.progress == Double(Float.leastNonzeroMagnitude))
        #expect(payload.velocityX == 600)
        #expect(payload.velocityY == 600)
    }

    @Test("dock swipe payload mirrors direction for left switches")
    func dockSwipePayloadMirrorsLeftDirection() {
        let payload = SpaceSwipePayload(phase: .changed, direction: .left, velocity: 600)

        #expect(payload.progress == -Double(Float.leastNonzeroMagnitude))
        #expect(payload.velocityX == -600)
        #expect(payload.velocityY == -600)
    }

    @Test("switch plan stops at boundaries when wrap around is disabled")
    func switchPlanStopsAtBoundariesWithoutWrapAround() {
        #expect(SpaceSwitchPlan.make(direction: .left, info: SpaceInfo(currentIndex: 0, spaceCount: 3), wrapAround: false) == [])
        #expect(SpaceSwitchPlan.make(direction: .right, info: SpaceInfo(currentIndex: 2, spaceCount: 3), wrapAround: false) == [])
    }

    @Test("switch plan wraps by walking the opposite direction")
    func switchPlanWrapsByWalkingOppositeDirection() {
        #expect(SpaceSwitchPlan.make(direction: .left, info: SpaceInfo(currentIndex: 0, spaceCount: 3), wrapAround: true) == [.right, .right])
        #expect(SpaceSwitchPlan.make(direction: .right, info: SpaceInfo(currentIndex: 2, spaceCount: 3), wrapAround: true) == [.left, .left])
    }

    @Test("switch result describes target space")
    func switchResultDescribesTargetSpace() {
        let result = SpaceSwitchResult.make(requestedDirection: .right, effectiveDirection: .right, info: SpaceInfo(currentIndex: 0, spaceCount: 3), wrapAround: true)

        #expect(result.switched == true)
        #expect(result.fromIndex == 0)
        #expect(result.toIndex == 1)
        #expect(result.spaceCount == 3)
    }

    @Test("switch result describes wrapped target space")
    func switchResultDescribesWrappedTargetSpace() {
        let result = SpaceSwitchResult.make(requestedDirection: .left, effectiveDirection: .left, info: SpaceInfo(currentIndex: 0, spaceCount: 3), wrapAround: true)

        #expect(result.switched == true)
        #expect(result.fromIndex == 0)
        #expect(result.toIndex == 2)
        #expect(result.plan == [.right, .right])
    }

    @Test("switch overlay model formats known target")
    func switchOverlayModelFormatsKnownTarget() {
        let model = DesktopSwitchOverlayModel(result: SpaceSwitchResult(
            requestedDirection: .right,
            effectiveDirection: .right,
            plan: [.right],
            fromIndex: 0,
            toIndex: 1,
            spaceCount: 3
        ))

        #expect(model.title == "Desktop 2")
        #expect(model.subtitle == "2 of 3")
    }

    @Test("desktop scroll accumulator waits for threshold before switching")
    func desktopScrollAccumulatorWaitsForThreshold() {
        var accumulator = DesktopScrollAccumulator(threshold: 6)

        #expect(accumulator.apply(delta: 2) == nil)
        #expect(accumulator.apply(delta: 3) == nil)
        #expect(accumulator.apply(delta: 1) == .right)
        #expect(accumulator.apply(delta: -6) == .left)
    }

    @Test("animated dock swipe uses progressive frames")
    func animatedDockSwipeUsesProgressiveFrames() {
        let frames = SpaceSwipeSequence.make(direction: .right, animateScroll: true, animatedVelocity: 600, instantVelocity: 3000)

        #expect(frames.count > 3)
        #expect(frames.first?.phase == .began)
        #expect(frames.last?.phase == .ended)
        #expect(frames.contains { $0.phase == .changed && $0.progress > 0.5 })
        #expect(frames.allSatisfy { $0.delay >= 0 })
    }

    @Test("instant dock swipe uses compact high velocity sequence")
    func instantDockSwipeUsesCompactSequence() {
        let frames = SpaceSwipeSequence.make(direction: .right, animateScroll: false, animatedVelocity: 600, instantVelocity: 3000)

        #expect(frames.count == 3)
        #expect(frames.map(\.phase) == [.began, .changed, .ended])
        #expect(frames.allSatisfy { $0.velocityX == 3000 })
    }
}
