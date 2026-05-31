import CoreGraphics
import Testing
@testable import ScrolodexCore

@MainActor
@Suite("Navigation coordinator")
struct NavigationCoordinatorTests {
    private func makeCandidate(id: CGWindowID, owner: String, title: String? = nil, bounds: CGRect = CGRect(x: 0, y: 0, width: 400, height: 400)) -> WindowCandidate {
        WindowCandidate(cgWindowID: id, ownerPID: pid_t(id), ownerName: owner, windowTitle: title, bounds: bounds, layer: 0, alpha: 1)
    }

    private func makeContext(
        scope: TriggerScope = .underCursor,
        filter: TriggerFilter = .allApps,
        overlayMode: OverlayPresentationMode = .default,
        peekEnabled: Bool = true,
        peekOpacity: Double = 0.94,
        theme: OverlayTheme = .default,
        monitorScope: MonitorScope = .currentMonitor,
        invertDirection: Bool = false,
        animate: Bool = true,
        wrapAround: Bool = true,
        scrollThreshold: Double = 6,
        dockBundleID: String? = nil
    ) -> TriggerContext {
        TriggerContext(
            scope: scope, filter: filter, overlayMode: overlayMode,
            peekEnabled: peekEnabled, peekOpacity: peekOpacity, theme: theme,
            monitorScope: monitorScope, invertDirection: invertDirection,
            animate: animate, wrapAround: wrapAround,
            scrollThreshold: scrollThreshold, dockBundleID: dockBundleID)
    }

    @Test("cursor relocation refreshes candidates when distance threshold exceeded")
    func cursorRelocationRefreshesCandidates() {
        let setA = [
            makeCandidate(id: 10, owner: "A1"),
            makeCandidate(id: 11, owner: "A2")
        ]
        let setB = [
            makeCandidate(id: 20, owner: "B1"),
            makeCandidate(id: 21, owner: "B2")
        ]
        let provider = PositionalMockProvider(nearby: setA, far: setB)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        #expect(overlay.lastCandidates?.first?.cgWindowID == 10)

        coordinator.handleCursorMove(cursor: CGPoint(x: 150, y: 100))
        #expect(overlay.lastCandidates?.first?.cgWindowID == 20)

        #expect(overlay.showCount == 2)
    }

    @Test("cursor relocation preserves selection when window still present in new stack")
    func cursorRelocationPreservesSelection() {
        let setA = [
            makeCandidate(id: 10, owner: "A1"),
            makeCandidate(id: 11, owner: "A2")
        ]
        let setB = [
            makeCandidate(id: 20, owner: "B1"),
            makeCandidate(id: 11, owner: "A2")
        ]
        let provider = PositionalMockProvider(nearby: setA, far: setB)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        for _ in 0..<6 {
            coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        }
        #expect(overlay.lastSelected?.cgWindowID == 11)

        coordinator.handleCursorMove(cursor: CGPoint(x: 150, y: 100))
        #expect(overlay.lastSelected?.cgWindowID == 11)
        #expect(overlay.lastCandidates?.map(\.cgWindowID) == [20, 11])
    }

    @Test("cursor relocation resets selection when window absent from new stack")
    func cursorRelocationResetsSelectionWhenWindowAbsent() {
        let setA = [
            makeCandidate(id: 10, owner: "A1"),
            makeCandidate(id: 11, owner: "A2")
        ]
        let setB = [
            makeCandidate(id: 20, owner: "B1"),
            makeCandidate(id: 21, owner: "B2")
        ]
        let provider = PositionalMockProvider(nearby: setA, far: setB)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        for _ in 0..<6 {
            coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        }
        #expect(overlay.lastSelected?.cgWindowID == 11)

        coordinator.handleCursorMove(cursor: CGPoint(x: 150, y: 100))
        #expect(overlay.lastSelected?.cgWindowID == 20)
    }

    @Test("cursor relocation skips rebuild when same window set")
    func cursorRelocationSkipsRebuildForSameWindowSet() {
        let setA = [
            makeCandidate(id: 10, owner: "A1"),
            makeCandidate(id: 11, owner: "A2")
        ]
        let provider = PositionalMockProvider(nearby: setA, far: setA)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        let showCountBefore = overlay.showCount

        coordinator.handleCursorMove(cursor: CGPoint(x: 150, y: 100))
        #expect(overlay.showCount == showCountBefore)
        #expect(overlay.repositionCount == 1)
    }

    @Test("cursor move repositions overlay even with single candidate")
    func cursorMoveRepositionsWithSingleCandidate() {
        let candidate = makeCandidate(id: 10, owner: "A1")
        let provider = MockWindowStackProvider(candidates: [candidate])
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        #expect(overlay.showCount == 1)

        coordinator.handleCursorMove(cursor: CGPoint(x: 150, y: 100))
        #expect(overlay.showCount == 1)
        #expect(overlay.repositionCount == 1)
    }

    @Test("scroll at moved cursor refreshes under-cursor candidates")
    func scrollAtMovedCursorRefreshesCandidates() {
        let setA = [
            makeCandidate(id: 10, owner: "A1"),
            makeCandidate(id: 11, owner: "A2")
        ]
        let setB = [
            makeCandidate(id: 20, owner: "B1"),
            makeCandidate(id: 21, owner: "B2")
        ]
        let provider = PositionalMockProvider(nearby: setA, far: setB)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        #expect(overlay.lastCandidates?.first?.cgWindowID == 10)

        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 150, y: 100))
        #expect(overlay.lastCandidates?.first?.cgWindowID == 20)
    }

    @Test("cursor relocation ignored for currentScreen scope")
    func cursorRelocationIgnoredForCurrentScreen() {
        let setA = [
            makeCandidate(id: 10, owner: "A1"),
            makeCandidate(id: 11, owner: "A2")
        ]
        let provider = PositionalMockProvider(nearby: setA, far: setA)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.activate(makeContext(scope: .currentScreen))
        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        let showCountBefore = overlay.showCount

        coordinator.handleCursorMove(cursor: CGPoint(x: 200, y: 200))
        #expect(overlay.showCount == showCountBefore)
        #expect(overlay.repositionCount == 1)
        #expect(overlay.lastRepositionCursor == CGPoint(x: 200, y: 200))
    }

    @Test("cursor relocation ignored when distance below threshold")
    func cursorRelocationIgnoredBelowThreshold() {
        let setA = [
            makeCandidate(id: 10, owner: "A1"),
            makeCandidate(id: 11, owner: "A2")
        ]
        let provider = PositionalMockProvider(nearby: setA, far: setA)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        let showCountBefore = overlay.showCount

        coordinator.handleCursorMove(cursor: CGPoint(x: 120, y: 100))
        #expect(overlay.showCount == showCountBefore)
        #expect(overlay.repositionCount == 1)
        #expect(overlay.lastRepositionCursor == CGPoint(x: 120, y: 100))
    }

    @Test("handleScroll starts session with 2+ candidates")
    func startsSessionWithEnoughCandidates() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2")
        ]
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -3, cursor: CGPoint.zero)

        #expect(overlay.showCount == 1)
        #expect(overlay.lastCandidates?.count == 2)
    }

    @Test("handleScroll does not start session with fewer than 2 candidates")
    func doesNotStartSessionWithOneCandidate() {
        let candidates = [makeCandidate(id: 1, owner: "App1")]
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -3, cursor: CGPoint.zero)

        #expect(overlay.showCount == 1)
        #expect(overlay.lastSelected == candidates.first)
    }

    @Test("scroll delta advances selection through candidates")
    func scrollAdvancesSelection() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2"),
            makeCandidate(id: 3, owner: "App3")
        ]
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint.zero)
        #expect(overlay.lastSelected?.cgWindowID == 1)

        for _ in 0..<6 {
            coordinator.handleScroll(delta: -1, cursor: CGPoint.zero)
        }
        #expect(overlay.lastSelected?.cgWindowID == 3)
    }

    @Test("first keyboard navigation primes initial selection before showing advanced selection")
    func firstKeyboardNavigationPrimesInitialSelection() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2"),
            makeCandidate(id: 3, owner: "App3")
        ]
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleKeyboardNavigation(direction: 1, cursor: CGPoint.zero)

        #expect(overlay.selectedIDs == [1, 2])
        #expect(overlay.lastSelected?.cgWindowID == 2)
    }

    @Test("sub-threshold scroll after session start does not redraw selection")
    func subThresholdScrollDoesNotRedrawSelection() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2"),
            makeCandidate(id: 3, owner: "App3")
        ]
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: 2, cursor: CGPoint.zero)
        #expect(overlay.showCount == 1)
        #expect(overlay.lastSelected?.cgWindowID == 1)

        coordinator.handleScroll(delta: 2, cursor: CGPoint.zero)
        #expect(overlay.showCount == 1)
        #expect(overlay.lastSelected?.cgWindowID == 1)
    }

    @Test("previewTrigger shows candidates and starts session")
    func previewTriggerShowsCandidates() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2")
        ]
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.previewTrigger(context: makeContext(overlayMode: .tile, peekEnabled: true, peekOpacity: 0.42, theme: .light), cursor: CGPoint.zero, hotkeyName: "Test")

        #expect(overlay.showCount == 1)
        #expect(overlay.lastCandidates?.count == 2)
        #expect(overlay.lastDisplay?.presentationMode == .tile)
        #expect(overlay.lastDisplay?.peekEnabled == true)
        #expect(overlay.lastDisplay?.peekOpacity == 0.42)
        #expect(overlay.lastDisplay?.theme == .light)
    }

    @Test("previewTrigger with currentScreen uses allCandidates")
    func previewTriggerAllWindows() {
        let cursorCandidates = [makeCandidate(id: 1, owner: "App1")]
        let allCandidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2"),
            makeCandidate(id: 3, owner: "App3")
        ]
        let provider = MockWindowStackProvider(candidates: cursorCandidates, allCandidates: allCandidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.previewTrigger(context: makeContext(scope: .currentScreen), cursor: CGPoint.zero, hotkeyName: "All Windows")

        #expect(overlay.lastCandidates?.count == 3)
    }

    @Test("currentScreen scroll updates overlay at live cursor")
    func currentScreenScrollUsesLiveCursor() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1", bounds: CGRect(x: 0, y: 0, width: 400, height: 400)),
            makeCandidate(id: 2, owner: "App2", bounds: CGRect(x: 500, y: 500, width: 400, height: 400))
        ]
        let provider = MockWindowStackProvider(candidates: [], allCandidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.activate(makeContext(scope: .currentScreen))
        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 100))
        coordinator.handleScroll(delta: -6, cursor: CGPoint(x: 300, y: 300))

        #expect(overlay.lastCursor == CGPoint(x: 300, y: 300))
    }

    @Test("dock hover scroll keeps overlay anchored to initial dock icon")
    func dockHoverScrollKeepsInitialAnchor() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App1")
        ]
        let provider = MockWindowStackProvider(candidates: [], allCandidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)
        let initialAnchor = CGPoint(x: 100, y: 900)

        coordinator.activate(makeContext(scope: .dockHover, dockBundleID: "com.example.App1"))
        coordinator.handleScroll(delta: -1, cursor: initialAnchor)
        coordinator.handleScroll(delta: -6, cursor: CGPoint(x: 600, y: 400))

        #expect(overlay.lastCursor == initialAnchor)
    }

    @Test("dock hover uses active monitor scope")
    func dockHoverUsesActiveMonitorScope() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App1")
        ]
        let provider = MockWindowStackProvider(candidates: [], allCandidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.activate(makeContext(scope: .dockHover, monitorScope: .allMonitors, dockBundleID: "com.example.App1"))
        coordinator.handleScroll(delta: -1, cursor: CGPoint(x: 100, y: 900))

        #expect(provider.lastAppMonitorScope == .allMonitors)
    }

    @Test("previewTrigger can request all monitors")
    func previewTriggerAllMonitors() {
        let cursorCandidates = [makeCandidate(id: 1, owner: "App1")]
        let allCandidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2")
        ]
        let provider = MockWindowStackProvider(candidates: cursorCandidates, allCandidates: allCandidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.previewTrigger(context: makeContext(scope: .currentScreen, monitorScope: .allMonitors), cursor: CGPoint.zero, hotkeyName: "All Windows")

        #expect(provider.usedAllMonitors == true)
        #expect(overlay.lastCandidates?.count == 2)
    }

    @Test("confirm raises selected window and hides overlay")
    func confirmRaisesAndHides() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2")
        ]
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint.zero)
        coordinator.confirm()

        #expect(raiser.raisedCandidate != nil)
        #expect(raiser.raisedCandidate?.cgWindowID == 1)
        #expect(overlay.hideCount == 1)
    }

    @Test("confirm hides overlay before raising selected window")
    func confirmHidesBeforeRaising() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2")
        ]
        let recorder = CallRecorder()
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter(recorder: recorder)
        let raiser = MockWindowRaiser(recorder: recorder)
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint.zero)
        coordinator.confirm()

        #expect(recorder.events == ["hide", "raise"])
    }

    @Test("confirm without session does nothing")
    func confirmWithoutSession() {
        let provider = MockWindowStackProvider(candidates: [])
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.confirm()

        #expect(raiser.raisedCandidate == nil)
        #expect(overlay.hideCount == 0)
    }

    @Test("handleTriggerRelease confirms when session active")
    func triggerReleaseConfirms() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2")
        ]
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint.zero)
        coordinator.handleTriggerRelease()

        #expect(raiser.raisedCandidate != nil)
        #expect(overlay.hideCount == 1)
    }

    @Test("handleTriggerRelease hides overlay when no session")
    func triggerReleaseHidesWithoutSession() {
        let provider = MockWindowStackProvider(candidates: [])
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleTriggerRelease()

        #expect(raiser.raisedCandidate == nil)
        #expect(overlay.hideCount == 1)
    }

    @Test("cancel clears session and hides overlay")
    func cancelClearsSession() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2")
        ]
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint.zero)
        coordinator.cancel()

        #expect(overlay.hideCount == 1)
        #expect(raiser.raisedCandidate == nil)

        coordinator.handleTriggerRelease()
        #expect(overlay.hideCount == 2)
    }

	@Test("cancel without session still hides overlay")
	func cancelWithoutSessionHides() {
		let provider = MockWindowStackProvider(candidates: [])
		let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.cancel()

		#expect(overlay.hideCount == 1)
	}

	@Test("desktop cursor move repositions overlay without window session")
	func desktopCursorMoveRepositionsWithoutWindowSession() {
		let provider = MockWindowStackProvider(candidates: [])
		let overlay = MockOverlayPresenter()
		let raiser = MockWindowRaiser()
		let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

		coordinator.handleDesktopCursorMove(cursor: CGPoint(x: 200, y: 300))

		#expect(overlay.repositionCount == 1)
		#expect(overlay.lastRepositionCursor == CGPoint(x: 200, y: 300))
		#expect(overlay.showCount == 0)
	}

	@Test("desktop trigger release hides overlay without window session")
	func desktopTriggerReleaseHidesOverlayWithoutWindowSession() {
		let provider = MockWindowStackProvider(candidates: [])
		let overlay = MockOverlayPresenter()
		let raiser = MockWindowRaiser()
		let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

		coordinator.handleDesktopTriggerRelease()

		#expect(overlay.hideCount == 1)
		#expect(overlay.showCount == 0)
	}

	@Test("selection wraps through candidates")
	func selectionWraps() {
        let candidates = [
            makeCandidate(id: 1, owner: "App1"),
            makeCandidate(id: 2, owner: "App2")
        ]
        let provider = MockWindowStackProvider(candidates: candidates)
        let overlay = MockOverlayPresenter()
        let raiser = MockWindowRaiser()
        let coordinator = makeCoordinator(provider: provider, overlay: overlay, raiser: raiser)

        coordinator.handleScroll(delta: -1, cursor: CGPoint.zero)

        for _ in 0..<6 {
            coordinator.handleScroll(delta: -1, cursor: CGPoint.zero)
        }
        #expect(overlay.lastSelected?.cgWindowID == 2)
        #expect(overlay.lastTransitionDirection == 0)

        for _ in 0..<6 {
            coordinator.handleScroll(delta: -1, cursor: CGPoint.zero)
        }
        #expect(overlay.lastSelected?.cgWindowID == 1)
        #expect(overlay.lastTransitionDirection == -1)
    }

    private func makeCoordinator(provider: some WindowStackProviding, overlay: MockOverlayPresenter, raiser: MockWindowRaiser) -> NavigationCoordinator {
        let coordinator = NavigationCoordinator(
            windowStackProvider: provider,
            overlayController: overlay,
            accessibilityWindowController: raiser
        )
        coordinator.activate(makeContext())
        return coordinator
    }
}

@MainActor
private final class MockWindowStackProvider: WindowStackProviding {
    private let candidates: [WindowCandidate]
    private let all: [WindowCandidate]
    private(set) var usedAllMonitors = false
    private(set) var lastAppMonitorScope: MonitorScope?

    init(candidates: [WindowCandidate], allCandidates: [WindowCandidate]? = nil) {
        self.candidates = candidates
        self.all = allCandidates ?? candidates
    }

    func candidates(matching query: WindowStackQuery) -> [WindowCandidate] {
        if query.scope == .dockHover {
            lastAppMonitorScope = query.monitorScope
            return all
        }
        if query.scope == .currentScreen {
            usedAllMonitors = query.monitorScope == .allMonitors
            return all
        }
        return candidates
    }
}

@MainActor
private final class MockOverlayPresenter: OverlayPresenting {
    private let recorder: CallRecorder?
    private(set) var showCount = 0
    private(set) var hideCount = 0
    private(set) var lastCandidates: [WindowCandidate]?
    private(set) var lastSelected: WindowCandidate?
    private(set) var lastCursor: CGPoint?
    private(set) var lastTransitionDirection: Int?
    private(set) var selectedIDs: [CGWindowID?] = []
    private(set) var lastDisplay: OverlayDisplayConfig?

    init(recorder: CallRecorder? = nil) {
        self.recorder = recorder
    }

    func showStack(candidates: [WindowCandidate], selected: WindowCandidate?, at cursor: CGPoint, scope: TriggerScope, transitionDirection: Int, preserveVisibleFrame: Bool, display: OverlayDisplayConfig) {
        showCount += 1
        lastCandidates = candidates
        lastSelected = selected
        lastCursor = cursor
        lastTransitionDirection = transitionDirection
        selectedIDs.append(selected?.cgWindowID)
        lastDisplay = display
    }

    func showDesktopSwitch(title: String, subtitle: String, selectedIndex: Int, totalCount: Int, at cursor: CGPoint, display: OverlayDisplayConfig) {}

    private(set) var repositionCount = 0
    private(set) var lastRepositionCursor: CGPoint?

    func repositionOverlay(to cursor: CGPoint) {
        repositionCount += 1
        lastRepositionCursor = cursor
    }

    func hide() {
        hideCount += 1
        recorder?.record("hide")
    }
}

@MainActor
private final class MockWindowRaiser: WindowRaising {
    private let recorder: CallRecorder?
    private(set) var raisedCandidate: WindowCandidate?

    init(recorder: CallRecorder? = nil) {
        self.recorder = recorder
    }

    func raise(candidate: WindowCandidate) {
        raisedCandidate = candidate
        recorder?.record("raise")
    }
}

private final class CallRecorder {
    private(set) var events: [String] = []

    func record(_ event: String) {
        events.append(event)
    }
}

@MainActor
private final class PositionalMockProvider: WindowStackProviding {
    private let nearby: [WindowCandidate]
    private let far: [WindowCandidate]
    private let splitX: CGFloat = 140

    init(nearby: [WindowCandidate], far: [WindowCandidate]) {
        self.nearby = nearby
        self.far = far
    }

    func candidates(matching query: WindowStackQuery) -> [WindowCandidate] {
        switch query.scope {
        case .underCursor:
            return query.cursor.x < splitX ? nearby : far
        case .currentScreen, .dockHover:
            return nearby
        }
    }
}
