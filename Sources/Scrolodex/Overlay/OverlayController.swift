import AppKit
import ScrolodexCore

@MainActor
final class OverlayController: OverlayPresenting {
	private var panel: NSPanel?
	private var peekPanel: NSPanel?
	private var badgePanel: NSPanel?
	private var tilePanel: NSPanel?
	private let contentView = OverlayView()
	private let peekView = PeekSnapshotView()
	private let badgeView = PeekBadgeView()
	private let tileView = TileOverlayView()
	private let thumbnails = ThumbnailProvider()
	private let appIcons = AppIconProvider()
	private var initialPeekWindowID: CGWindowID?
	private var smoothedCursor: CGPoint?
	private var targetCursor: CGPoint?
	private let smoothing: CGFloat = 0.45
	private var convergenceTimer: DispatchSourceTimer?

	func showStack(
		candidates: [WindowCandidate], selected: WindowCandidate?, at cursor: CGPoint,
		scope: TriggerScope = .underCursor, transitionDirection: Int = 0, preserveVisibleFrame: Bool = false,
		display: OverlayDisplayConfig
	) {
		applyTheme(display.theme)

		if display.peekEnabled {
			showSnapshotPeek(candidates: candidates, selected: selected, scope: scope, peekOpacity: display.peekOpacity)
		} else {
			peekPanel?.orderOut(nil)
		}

		if display.presentationMode == .tooltip {
			showBadge(candidates: candidates, selected: selected, cursor: cursor)
		} else {
			badgePanel?.orderOut(nil)
		}

		if display.presentationMode == .none {
			panel?.orderOut(nil)
			tilePanel?.orderOut(nil)
			return
		}

		if display.presentationMode == .tooltip {
			panel?.orderOut(nil)
			tilePanel?.orderOut(nil)
			return
		}

		let model = WindowStackOverlayModel(candidates: candidates, selected: selected, scope: scope)
		let visible = Self.visibleWindow(
			around: model.rows, selectedIndex: model.selectedIndex, count: display.scrollAnimationEnabled ? 5 : 3)
		let selectedIndex =
			display.scrollAnimationEnabled
			? model.selectedIndex
			: (visible.rows.firstIndex(where: { $0.isSelected }) ?? visible.rows.count / 2)
		let rowIndexOffset = display.scrollAnimationEnabled ? visible.offset : 0
		let candidateByID = Dictionary(uniqueKeysWithValues: candidates.map { ($0.cgWindowID, $0) })
		let rowViewModels: [OverlayRowViewModel] = visible.rows.map { row in
			let candidate = candidateByID[row.windowID]
			return OverlayRowViewModel(
				windowID: row.windowID,
				primaryText: row.primaryText,
				secondaryText: row.secondaryText,
				isSelected: row.isSelected,
				thumbnail: thumbnails.thumbnail(for: row.windowID),
				appIcon: candidate.flatMap { appIcons.icon(for: $0.ownerPID, ownerName: $0.ownerName) }
			)
		}

		if display.presentationMode == .tile {
			panel?.orderOut(nil)
			showTile(
				model: model, rowViewModels: rowViewModels, selectedIndex: selectedIndex,
				rowIndexOffset: rowIndexOffset, transitionDirection: transitionDirection,
				candidates: candidates, selected: selected, preserveVisibleFrame: preserveVisibleFrame,
				scrollAnimationEnabled: display.scrollAnimationEnabled)
			return
		}

		tilePanel?.orderOut(nil)
		let panel = panel ?? makePanel(contentView: contentView)
		self.panel = panel
		contentView.configure(
			rows: rowViewModels,
			selectedIndex: selectedIndex,
			rowIndexOffset: rowIndexOffset,
			transitionDirection: transitionDirection,
			animationEnabled: display.scrollAnimationEnabled
		)
		if !preserveVisibleFrame || !panel.isVisible {
			let anchor = selected ?? candidates.first
			let anchorBounds = anchor.map { resolveAppKitFrame(from: $0.bounds) }
			let frame = OverlayPlacement.listOverlayFrame(
				candidateCount: candidates.count,
				selectedBounds: anchorBounds,
				cursor: NSEvent.mouseLocation,
				screens: NSScreen.screens.map(\.frame)
			)
			panel.setFrame(frame, display: true)
		}
		panel.orderFrontRegardless()
		contentView.needsDisplay = true
		Log.debug("overlay shown title=%@ rows=%d", model.title, model.rows.count)
	}

	private func applyTheme(_ theme: OverlayTheme) {
		let tokens = OverlayColorTokens.tokens(for: theme.resolved)
		contentView.colorTokens = tokens
		tileView.colorTokens = tokens
		badgeView.colorTokens = tokens
		peekView.colorTokens = tokens
	}

	func hide() {
		panel?.orderOut(nil)
		peekPanel?.orderOut(nil)
		badgePanel?.orderOut(nil)
		tilePanel?.orderOut(nil)
		initialPeekWindowID = nil
		smoothedCursor = nil
		targetCursor = nil
		stopConvergenceTimer()
		thumbnails.clear()
		appIcons.clear()
		Log.debug("overlay hidden")
	}

	func repositionOverlay(to cursor: CGPoint) {
		let mappings = screenMappings()
		let appKitCursor = OverlayPlacement.appKitPoint(fromCGDisplayPoint: cursor, screens: mappings)
		targetCursor = appKitCursor

		guard let badgePanel, badgePanel.isVisible else { return }

		if let current = smoothedCursor {
			smoothedCursor = CGPoint(
				x: current.x + (appKitCursor.x - current.x) * smoothing,
				y: current.y + (appKitCursor.y - current.y) * smoothing)
		} else {
			smoothedCursor = appKitCursor
		}
		applySmoothedFrame(badgePanel: badgePanel)

		if !isConverged {
			ensureConvergenceTimer(badgePanel: badgePanel)
		}
	}

	private func applySmoothedFrame(badgePanel: NSPanel) {
		guard let smoothedCursor else { return }
		let screenFrames = NSScreen.screens.map(\.frame)
		let frame = CursorTooltipPlacement.frame(
			size: badgeView.preferredSize(), cursor: smoothedCursor, screens: screenFrames)
		badgePanel.setFrame(frame, display: false)
	}

	private var isConverged: Bool {
		guard let smoothedCursor, let targetCursor else { return true }
		return abs(smoothedCursor.x - targetCursor.x) < 0.5
			&& abs(smoothedCursor.y - targetCursor.y) < 0.5
	}

	private func ensureConvergenceTimer(badgePanel: NSPanel) {
		guard convergenceTimer == nil else { return }
		let t = DispatchSource.makeTimerSource(queue: .main)
		t.schedule(deadline: .now(), repeating: .milliseconds(16))
		t.setEventHandler { [weak self] in
			Task { @MainActor [weak self] in
				self?.convergenceTick()
			}
		}
		t.resume()
		convergenceTimer = t
	}

	private func convergenceTick() {
		guard let target = targetCursor, let current = smoothedCursor else {
			stopConvergenceTimer()
			return
		}
		smoothedCursor = CGPoint(
			x: current.x + (target.x - current.x) * smoothing,
			y: current.y + (target.y - current.y) * smoothing)

		guard let badgePanel, badgePanel.isVisible else {
			stopConvergenceTimer()
			return
		}
		applySmoothedFrame(badgePanel: badgePanel)

		if isConverged {
			smoothedCursor = target
			applySmoothedFrame(badgePanel: badgePanel)
			stopConvergenceTimer()
		}
	}

	private func stopConvergenceTimer() {
		convergenceTimer?.cancel()
		convergenceTimer = nil
	}

	func showDesktopSwitch(title: String, subtitle: String, selectedIndex: Int, totalCount: Int, at cursor: CGPoint, display: OverlayDisplayConfig)
	{
		applyTheme(display.theme)
		panel?.orderOut(nil)
		tilePanel?.orderOut(nil)
		peekPanel?.orderOut(nil)
		badgeView.appIcon = nil
		badgeView.selectedIndex = selectedIndex
		badgeView.totalCount = totalCount
		showBadge(title: title, subtitle: subtitle, cursor: cursor)
	}

	private func showSnapshotPeek(candidates: [WindowCandidate], selected: WindowCandidate?, scope: TriggerScope, peekOpacity: Double) {
		guard let selected else {
			peekPanel?.orderOut(nil)
			return
		}

		if initialPeekWindowID == nil {
			initialPeekWindowID = selected.cgWindowID
		}

		let borderOnly = PeekPresentationPolicy.usesBorderOnly(
			scope: scope,
			isInitialSelection: selected.cgWindowID == initialPeekWindowID
		)
		let snapshot = borderOnly ? nil : thumbnails.thumbnail(for: selected.cgWindowID)

		guard borderOnly || snapshot != nil else {
			peekPanel?.orderOut(nil)
			return
		}

		let panel = peekPanel ?? makePanel(contentView: peekView)
		peekPanel = panel
		peekView.image = snapshot
		peekView.imageOpacity = CGFloat(max(0, min(1, peekOpacity)))
		peekView.borderOnly = borderOnly
		panel.setFrame(resolveAppKitFrame(from: selected.bounds), display: true)
		panel.orderFrontRegardless()
		peekView.needsDisplay = true
		Log.debug("peek shown title=%@ candidates=%d", badgeView.title, candidates.count)
	}

	private func showBadge(candidates: [WindowCandidate], selected: WindowCandidate?, cursor: CGPoint) {
		guard let selected else {
			badgePanel?.orderOut(nil)
			return
		}

		let title = selected.windowTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
		badgeView.appIcon = appIcons.icon(for: selected.ownerPID, ownerName: selected.ownerName)
		badgeView.selectedIndex = selectionPosition(in: candidates, selected: selected)
		badgeView.totalCount = candidates.count
		showBadge(
			title: title.flatMap { $0.isEmpty ? nil : $0 } ?? selected.ownerName,
			subtitle:
				"\(selected.ownerName) • \(selectionPosition(in: candidates, selected: selected)) of \(candidates.count)",
			cursor: cursor
		)
	}

	private func showBadge(title: String, subtitle: String, cursor: CGPoint) {
		let panel = badgePanel ?? makePanel(contentView: badgeView)
		badgePanel = panel
		panel.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
		badgeView.title = title
		badgeView.subtitle = subtitle
		let size = badgeView.preferredSize()
		let mappings = screenMappings()
		let appKitCursor = OverlayPlacement.appKitPoint(fromCGDisplayPoint: cursor, screens: mappings)
		smoothedCursor = appKitCursor
		let frame = CursorTooltipPlacement.frame(
			size: size,
			cursor: appKitCursor,
			screens: NSScreen.screens.map(\.frame)
		)
		panel.setFrame(frame, display: true)
		panel.orderFrontRegardless()
		badgeView.needsDisplay = true
	}

	private func showTile(
		model: WindowStackOverlayModel,
		rowViewModels: [OverlayRowViewModel],
		selectedIndex: Int,
		rowIndexOffset: Int,
		transitionDirection: Int,
		candidates: [WindowCandidate],
		selected: WindowCandidate?,
		preserveVisibleFrame: Bool,
		scrollAnimationEnabled: Bool
	) {
		let panel = tilePanel ?? makePanel(contentView: tileView)
		tilePanel = panel
		tileView.configure(
			rows: rowViewModels,
			selectedIndex: selectedIndex,
			rowIndexOffset: rowIndexOffset,
			transitionDirection: transitionDirection,
			animationEnabled: scrollAnimationEnabled
		)
		if !preserveVisibleFrame || !panel.isVisible {
			let anchor = selected ?? candidates.first
			let anchorBounds = anchor.map { resolveAppKitFrame(from: $0.bounds) }
			let frame = OverlayPlacement.tileOverlayFrame(
				candidateCount: candidates.count,
				selectedBounds: anchorBounds,
				cursor: NSEvent.mouseLocation,
				screens: NSScreen.screens.map(\.frame)
			)
			panel.setFrame(frame, display: true)
		}
		panel.orderFrontRegardless()
		tileView.needsDisplay = true
		Log.debug("tile overlay shown title=%@ rows=%d", model.title, model.rows.count)
	}

	private func selectionPosition(in candidates: [WindowCandidate], selected: WindowCandidate) -> Int {
		(candidates.firstIndex(of: selected) ?? 0) + 1
	}

	private func makePanel(contentView: NSView) -> NSPanel {
		let panel = NSPanel(
			contentRect: .zero,
			styleMask: [.borderless, .nonactivatingPanel],
			backing: .buffered,
			defer: false
		)
		panel.backgroundColor = .clear
		panel.isOpaque = false
		panel.ignoresMouseEvents = true
		panel.level = .screenSaver
		panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
		panel.contentView = contentView
		return panel
	}

	private func resolveAppKitFrame(from cgBounds: CGRect) -> CGRect {
		let mappings = screenMappings()
		let desktopFrame = NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }
		let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
		let mouseLocation = NSEvent.mouseLocation
		let converted = OverlayPlacement.resolveAppKitFrame(
			fromCGWindowBounds: cgBounds,
			screenMappings: mappings,
			desktopUnionFrame: desktopFrame,
			primaryScreenHeight: primaryHeight,
			mouseLocation: mouseLocation
		)
		Log.debug(
			"convert cgBounds=%@ mouse=%@ appKitFrame=%@", NSStringFromRect(cgBounds),
			NSStringFromPoint(mouseLocation), NSStringFromRect(converted))
		return converted
	}

	private func screenMappings() -> [OverlayPlacement.ScreenMapping] {
		NSScreen.screens.compactMap { screen in
			guard
				let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
					as? NSNumber
			else {
				return nil
			}
			let displayID = CGDirectDisplayID(screenNumber.uint32Value)
			return OverlayPlacement.ScreenMapping(
				cgBounds: CGDisplayBounds(displayID), appKitFrame: screen.frame)
		}
	}

	private static func visibleWindow(around rows: [WindowStackOverlayModel.Row], selectedIndex: Int, count: Int)
		-> (rows: [WindowStackOverlayModel.Row], offset: Int)
	{
		let centerIndex = count / 2
		let padCount =
			max(0, centerIndex - selectedIndex)
			+ max(0, selectedIndex - (rows.count - 1 - centerIndex))
		let total = min(count, rows.count + padCount)
		let actualCenter = total / 2

		var result: [WindowStackOverlayModel.Row] = []
		let firstReal = selectedIndex - actualCenter
		for i in 0..<total {
			let realIndex = firstReal + i
			if realIndex >= 0 && realIndex < rows.count {
				result.append(rows[realIndex])
			} else {
				result.append(
					WindowStackOverlayModel.Row(
						windowID: 0,
						primaryText: "",
						secondaryText: "",
						isSelected: false
					))
			}
		}
		return (result, firstReal)
	}
}
