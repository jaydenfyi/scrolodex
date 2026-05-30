import CoreGraphics
import Foundation

@MainActor
public final class NavigationCoordinator {
	private let windowStackProvider: any WindowStackProviding
	private var overlayController: any OverlayPresenting
	private let accessibilityWindowController: any WindowRaising
	private var session: NavigationSession?
	private var sessionCandidates: [WindowCandidate] = []
	private var overlayAnchorSession = OverlayAnchorSession()
	private var context: TriggerContext?
	private var lastCandidateCursor: CGPoint?
	private var lastCursorMoveTime: CFAbsoluteTime = 0
	private let cursorRelocationThreshold: CGFloat = 40

	public init(
		windowStackProvider: any WindowStackProviding,
		overlayController: any OverlayPresenting,
		accessibilityWindowController: any WindowRaising,
		scrollThreshold: Double = ScrollSensitivity.default
	) {
		self.windowStackProvider = windowStackProvider
		self.overlayController = overlayController
		self.accessibilityWindowController = accessibilityWindowController
	}

	public func activate(_ context: TriggerContext) {
		self.context = context
	}

	public func previewTrigger(context: TriggerContext, cursor: CGPoint, hotkeyName: String) {
		activate(context)
		let candidates = collectCandidates(cursor: cursor)
		sessionCandidates = candidates
		let minCandidates = context.scope == .dockHover ? 1 : 2
		if candidates.count >= minCandidates, session == nil {
			session = NavigationSession(
				candidates: candidates, scrollThreshold: context.scrollThreshold,
				wrapAround: context.wrapAround)
			lastCandidateCursor = cursor
			_ = overlayAnchorSession.anchor(startingAt: cursor)
		}
		Log.debug(
			"trigger preview hotkey=%@ cursor=%@ candidates=%d scope=%@ filter=%@", hotkeyName,
			NSStringFromPoint(cursor), candidates.count, context.scope.rawValue,
			context.filter.rawValue)
		overlayController.showStack(
			candidates: candidates,
			selected: session?.selectedCandidate ?? candidates.first,
			at: overlayAnchorSession.anchor(startingAt: cursor),
			scope: context.scope,
			transitionDirection: 0,
			preserveVisibleFrame: session != nil,
			display: OverlayDisplayConfig(context: context)
		)
	}

	public func handleScroll(delta: Double, cursor: CGPoint) {
		guard let ctx = context else { return }
		let effectiveDelta = ctx.invertDirection ? -delta : delta
		Log.debug(
			"scroll delta=%f effective=%f cursor=%@ sessionActive=%@", delta, effectiveDelta,
			NSStringFromPoint(cursor), String(session != nil))
		var startedSession = false
		if session == nil {
			let candidates = collectCandidates(cursor: cursor)
			let minCandidates = ctx.scope == .dockHover ? 1 : 2
			sessionCandidates = candidates
			lastCandidateCursor = cursor
			guard candidates.count >= minCandidates else {
				overlayController.showStack(
					candidates: candidates, selected: candidates.first, at: cursor,
					scope: ctx.scope, transitionDirection: 0, preserveVisibleFrame: false,
					display: OverlayDisplayConfig(context: ctx))
				Log.debug("not starting session; need at least %d candidates, got %d", minCandidates, candidates.count)
				return
			}
			session = NavigationSession(
				candidates: candidates, scrollThreshold: ctx.scrollThreshold,
				wrapAround: ctx.wrapAround)
			lastCandidateCursor = cursor
			_ = overlayAnchorSession.anchor(startingAt: cursor)
			startedSession = true
			Log.debug("started session candidateCount=%d", candidates.count)
		} else if refreshCandidatesIfCursorRelocated(cursor: cursor) {
			startedSession = true
		}

		guard let movement = session?.applyScrollDelta(effectiveDelta) else { return }
		switch movement {
		case let .changed(direction, wrapped):
			showSelection(transitionDirection: wrapped ? 0 : direction, cursor: cursor)
		case .none:
			if startedSession {
				showSelection(transitionDirection: 0, cursor: cursor)
			}
		}
	}

	public func handleKeyboardNavigation(direction: Int, cursor: CGPoint) {
		guard let ctx = context else { return }
		if session == nil {
			let candidates = collectCandidates(cursor: cursor)
			let minCandidates = ctx.scope == .dockHover ? 1 : 2
			sessionCandidates = candidates
			lastCandidateCursor = cursor
			guard candidates.count >= minCandidates else {
				overlayController.showStack(
					candidates: candidates, selected: candidates.first, at: cursor,
					scope: ctx.scope, transitionDirection: 0, preserveVisibleFrame: false,
					display: OverlayDisplayConfig(context: ctx))
				return
			}
			session = NavigationSession(
				candidates: candidates, scrollThreshold: ctx.scrollThreshold,
				wrapAround: ctx.wrapAround)
			lastCandidateCursor = cursor
			_ = overlayAnchorSession.anchor(startingAt: cursor)
			showSelection(transitionDirection: 0, cursor: cursor)
		} else if refreshCandidatesIfCursorRelocated(cursor: cursor) {
		}

		guard let movement = session?.step(direction: direction) else { return }
		if case .changed = movement {
			showSelection(transitionDirection: movement.transitionDirection, cursor: cursor)
		}
	}

	public func handleCursorMove(cursor: CGPoint) {
		let now = CFAbsoluteTimeGetCurrent()
		guard now - lastCursorMoveTime >= 1.0 / 60.0 else { return }
		lastCursorMoveTime = now
		guard context != nil else { return }
		if refreshCandidatesIfCursorRelocated(cursor: cursor) {
			showSelection(transitionDirection: 0, cursor: cursor)
		} else {
			overlayController.repositionOverlay(to: cursor)
		}
	}

	public func confirm() {
		guard var activeSession = session else {
			Log.debug("confirm ignored; no active session")
			return
		}
		if case let .confirmed(candidate) = activeSession.confirm() {
			Log.info("confirmed window: %@ — %@", candidate.ownerName, candidate.windowTitle ?? "")
			clearSession()
			accessibilityWindowController.raise(candidate: candidate)
		}
	}

	public func handleTriggerRelease() {
		switch TriggerReleaseBehavior.action(hasActiveSession: session != nil) {
		case .confirm:
			Log.debug("trigger released; confirming active selection")
			confirm()
		case .none:
			Log.debug("trigger released; no active selection to confirm")
			overlayController.hide()
		}
	}

	public func showDesktopSwitch(result: SpaceSwitchResult, cursor: CGPoint) {
		let model = DesktopSwitchOverlayModel(result: result)
		let display = context.map { OverlayDisplayConfig(context: $0) } ?? .default
		overlayController.showDesktopSwitch(
			title: model.title, subtitle: model.subtitle,
			selectedIndex: model.selectedIndex, totalCount: model.totalCount, at: cursor,
			display: display)
	}

	public func cancel() {
		guard session != nil else {
			overlayController.hide()
			return
		}
		Log.debug("canceling session")
		clearSession()
	}

	private func showSelection(transitionDirection: Int, cursor: CGPoint) {
		guard let session, let ctx = context else { return }
		let selected = session.selectedCandidate
		let anchor =
			ctx.scope == .dockHover ? overlayAnchorSession.anchor(startingAt: cursor) : cursor
		overlayController.showStack(
			candidates: sessionCandidates,
			selected: selected,
			at: anchor,
			scope: ctx.scope,
			transitionDirection: ctx.animate ? transitionDirection : 0,
			preserveVisibleFrame: true,
			display: OverlayDisplayConfig(context: ctx)
		)
	}

	private func clearSession() {
		session = nil
		sessionCandidates = []
		overlayAnchorSession.reset()
		overlayController.hide()
	}

	private func refreshCandidatesIfCursorRelocated(cursor: CGPoint) -> Bool {
		guard let ctx = context, ctx.scope == .underCursor, let last = lastCandidateCursor else { return false }
		let dx = cursor.x - last.x
		let dy = cursor.y - last.y
		let distance = sqrt(dx * dx + dy * dy)
		guard distance >= cursorRelocationThreshold else { return false }

		let candidates = collectCandidates(cursor: cursor)
		guard !candidates.isEmpty else { return false }

		let oldIDs = Set(sessionCandidates.map(\.cgWindowID))
		let newIDs = Set(candidates.map(\.cgWindowID))
		if oldIDs == newIDs {
			lastCandidateCursor = cursor
			Log.debug("cursor relocated distance=%.0f; same window set, skipping rebuild", distance)
			return false
		}

		let restoredIndex: Int? = session.flatMap { currentSession in
			let previouslySelectedID = currentSession.selectedCandidate.cgWindowID
			return candidates.firstIndex(where: { $0.cgWindowID == previouslySelectedID })
		}

		sessionCandidates = candidates
		session = NavigationSession(
			candidates: candidates, scrollThreshold: ctx.scrollThreshold,
			wrapAround: ctx.wrapAround,
			initialSelectedIndex: restoredIndex ?? 0)
		lastCandidateCursor = cursor
		overlayAnchorSession.reset()
		_ = overlayAnchorSession.anchor(startingAt: cursor)
		Log.debug(
			"cursor relocated distance=%.0f; refreshed candidates=%d restoredSelection=%d",
			distance, candidates.count, restoredIndex ?? 0)
		return true
	}

	private func collectCandidates(cursor: CGPoint) -> [WindowCandidate] {
		guard let ctx = context else { return [] }
		return windowStackProvider.candidates(
			matching: WindowStackQuery(
				scope: ctx.scope,
				filter: ctx.filter,
				monitorScope: ctx.monitorScope,
				cursor: cursor,
				bundleID: ctx.dockBundleID
			))
	}
}
