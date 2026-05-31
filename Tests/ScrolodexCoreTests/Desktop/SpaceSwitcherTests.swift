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

    @Test("switch plan does not synthesize a swipe for a known single-space display")
    func switchPlanDoesNotSynthesizeSwipeForKnownSingleSpaceDisplay() {
        #expect(SpaceSwitchPlan.make(direction: .right, info: SpaceInfo(currentIndex: 0, spaceCount: 1), wrapAround: true) == [])
    }

    @Test("space info resolves current space from the matching display")
    func spaceInfoResolvesCurrentSpaceFromMatchingDisplay() {
        let displays: [[String: Any]] = [
            [
                "Display Identifier": "large-display",
                "Current Space": ["id64": 20],
                "Spaces": [["id64": 10], ["id64": 20], ["id64": 30]],
            ],
            [
                "Display Identifier": "small-display",
                "Current Space": ["id64": 200],
                "Spaces": [["id64": 100], ["id64": 200]],
            ],
        ]

        let info = SpaceInfo.fromManagedDisplaySpaces(displays, displayIdentifier: "small-display")

        #expect(info == SpaceInfo(currentIndex: 1, spaceCount: 2))
    }

    @Test("space info derives desktop label from global desktop order")
    func spaceInfoDerivesDesktopLabelFromGlobalDesktopOrder() {
        let displays: [[String: Any]] = [
            [
                "Display Identifier": "large-display",
                "Current Space": ["id64": 20],
                "Spaces": [["id64": 10, "type": 0], ["id64": 20, "type": 0]],
            ],
            [
                "Display Identifier": "small-display",
                "Current Space": ["id64": 30],
                "Spaces": [["id64": 30, "type": 0]],
            ],
        ]

        let info = SpaceInfo.fromManagedDisplaySpaces(displays, displayIdentifier: "small-display")

        #expect(info?.currentLabel == "Desktop 3")
    }

    @Test("switch overlay model resolves full-screen app label from target pid")
    func switchOverlayModelResolvesFullScreenAppLabelFromTargetPID() {
        let displays: [[String: Any]] = [
            [
                "Display Identifier": "target-display",
                "Current Space": ["id64": 30],
                "Spaces": [["id64": 30, "type": 0], ["id64": 40, "type": 4, "pid": 42]],
            ]
        ]
        let info = SpaceInfo.fromManagedDisplaySpaces(displays, displayIdentifier: "target-display")
        let result = SpaceSwitchResult.make(
            requestedDirection: .right, effectiveDirection: .right, info: info, wrapAround: true)

        let model = DesktopSwitchOverlayModel(result: result) { pid in
            pid == 42 ? "Google Chrome" : nil
        }

        #expect(model.title == "Google Chrome")
        #expect(model.subtitle == "2 of 2")
    }

    @Test("switch overlay model does not invent desktop label for full-screen app")
    func switchOverlayModelDoesNotInventDesktopLabelForFullScreenApp() {
        let result = SpaceSwitchResult(
            requestedDirection: .right,
            effectiveDirection: .right,
            plan: [.right],
            fromIndex: 0,
            toIndex: 1,
            spaceCount: 2,
            fromLabel: "Desktop 3",
            toLabel: nil,
            fromApplicationPID: nil,
            toApplicationPID: 42
        )

        let model = DesktopSwitchOverlayModel(result: result)

        #expect(model.title == "Space 2")
    }

    @Test("switch overlay model shows current desktop at boundary")
    func switchOverlayModelShowsCurrentDesktopAtBoundary() {
        let model = DesktopSwitchOverlayModel(result: SpaceSwitchResult(
            requestedDirection: .right,
            effectiveDirection: .right,
            plan: [],
            fromIndex: 0,
            toIndex: nil,
            spaceCount: 1,
            fromLabel: "Desktop 3",
            toLabel: nil
        ))

        #expect(model.title == "Desktop 3")
        #expect(model.subtitle == "1 of 1")
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
            spaceCount: 3,
            toLabel: "Desktop 2"
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

    @Test("desktop scroll accumulator preserves excess delta")
    func desktopScrollAccumulatorPreservesExcessDelta() {
        var accumulator = DesktopScrollAccumulator(threshold: 6)

        #expect(accumulator.apply(delta: 8) == .right)
        #expect(accumulator.apply(delta: 4) == .right)
        #expect(accumulator.apply(delta: -8) == .left)
    }

    @Test("desktop switch gate blocks overlapping swipe sequences")
    func desktopSwitchGateBlocksOverlappingSwipeSequences() {
        var gate = DesktopSwitchGate()
        let first = gate.begin(now: 1, duration: 0.2)
        let overlapping = gate.begin(now: 1.1, duration: 0.2)
        let afterCompletion = gate.begin(now: 1.2, duration: 0.2)

        #expect(first)
        #expect(!overlapping)
        #expect(afterCompletion)
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
