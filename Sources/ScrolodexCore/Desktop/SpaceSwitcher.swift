import ApplicationServices
import CoreGraphics
import Darwin
import Foundation

public enum SpaceSwitchDirection: Int, Sendable {
	case left = -1
	case right = 1
}

/// `@unchecked Sendable` is safe because:
/// - Mutable properties (`animateScroll`, `invertDirection`, `wrapAround`) are only set from
///   `EventTapController`'s main-run-loop callback via `applyDesktopSwitchTrigger()`.
/// - `switchDesktop()` is only called from the same callback.
/// - All access is serialized on the main thread.
///
/// Note: `postDockSwipe(frames:)` uses `DispatchQueue.main.asyncAfter` for delayed frames.
/// If properties change between frames, later frames may use stale values. This is benign —
/// it only affects animation smoothness during a property change mid-switch.
public final class SpaceSwitcher: @unchecked Sendable {
	private let animatedVelocity: Double = 600.0
	private let instantVelocity: Double = 3000.0

	public var animateScroll: Bool = true
	public var invertDirection: Bool = false
	public var wrapAround: Bool = true

	public init(animateScroll: Bool = true, invertDirection: Bool = false, wrapAround: Bool = true) {
		self.animateScroll = animateScroll
		self.invertDirection = invertDirection
		self.wrapAround = wrapAround
	}

	public func switchDesktop(direction: SpaceSwitchDirection) -> SpaceSwitchResult {
		switchDesktop(direction: direction, cursor: nil)
	}

	public func switchDesktop(direction: SpaceSwitchDirection, cursor: CGPoint?) -> SpaceSwitchResult {
		let effectiveDirection: SpaceSwitchDirection
		if invertDirection {
			effectiveDirection = direction == .left ? .right : .left
		} else {
			effectiveDirection = direction
		}

		let targetDisplayID = cursor.flatMap(Self.displayID(containing:))
		let info = SpaceInfo.current(displayID: targetDisplayID)

		let plan = SpaceSwitchPlan.make(
			direction: effectiveDirection,
			info: info,
			wrapAround: wrapAround
		)
		let result = SpaceSwitchResult.make(
			requestedDirection: direction,
			effectiveDirection: effectiveDirection,
			info: info,
			wrapAround: wrapAround
		)
		guard !plan.isEmpty else {
			Log.debug(
				"desktop switch ignored at boundary direction=%@",
				effectiveDirection == .left ? "left" : "right")
			return result
		}

		for plannedDirection in plan {
			let frames = SpaceSwipeSequence.make(
				direction: plannedDirection,
				animateScroll: animateScroll,
				animatedVelocity: animatedVelocity,
				instantVelocity: instantVelocity
			)
			postDockSwipe(frames: frames, cursor: cursor)
		}
		Log.info(
			"switched desktop direction=%@ animate=%@ steps=%d",
			effectiveDirection == .left ? "left" : "right", String(animateScroll), plan.count)
		return result
	}

	private static func displayID(containing point: CGPoint) -> CGDirectDisplayID? {
		var count: UInt32 = 0
		var displays = [CGDirectDisplayID](repeating: 0, count: 1)
		let error = CGGetDisplaysWithPoint(point, UInt32(displays.count), &displays, &count)
		guard error == .success, count > 0 else { return nil }
		return displays[0]
	}

	private func postDockSwipe(frames: [SpaceSwipeFrame], cursor: CGPoint?) {
		for frame in frames {
			if frame.delay == 0 {
				postDockSwipe(frame: frame, cursor: cursor)
			} else {
				DispatchQueue.main.asyncAfter(deadline: .now() + frame.delay) { [weak self] in
					self?.postDockSwipe(frame: frame, cursor: cursor)
				}
			}
		}
	}

	private func postDockSwipe(frame: SpaceSwipeFrame, cursor: CGPoint?) {
		guard let event = CGEvent(source: nil) else { return }
		if let cursor {
			event.location = cursor
		}

		event.setIntegerValueField(EventField.eventType, value: Int64(kCGSEventDockControl))
		event.setIntegerValueField(EventField.gestureHIDType, value: Int64(kIOHIDEventTypeDockSwipe))
		event.setIntegerValueField(EventField.gesturePhase, value: Int64(frame.phase.rawValue))
		event.setDoubleValueField(EventField.gestureSwipeProgress, value: frame.progress)
		event.setIntegerValueField(EventField.gestureSwipeMotion, value: Int64(kCGGestureMotionHorizontal))
		event.setDoubleValueField(EventField.gestureSwipeVelocityX, value: frame.velocityX)
		event.setDoubleValueField(EventField.gestureSwipeVelocityY, value: frame.velocityY)

		event.post(tap: .cgSessionEventTap)
	}
}

public struct SpaceSwitchResult: Equatable, Sendable {
	public let requestedDirection: SpaceSwitchDirection
	public let effectiveDirection: SpaceSwitchDirection
	public let plan: [SpaceSwitchDirection]
	public let fromIndex: Int?
	public let toIndex: Int?
	public let spaceCount: Int?
	public let fromLabel: String?
	public let toLabel: String?

	public init(
		requestedDirection: SpaceSwitchDirection,
		effectiveDirection: SpaceSwitchDirection,
		plan: [SpaceSwitchDirection],
		fromIndex: Int?,
		toIndex: Int?,
		spaceCount: Int?,
		fromLabel: String? = nil,
		toLabel: String? = nil
	) {
		self.requestedDirection = requestedDirection
		self.effectiveDirection = effectiveDirection
		self.plan = plan
		self.fromIndex = fromIndex
		self.toIndex = toIndex
		self.spaceCount = spaceCount
		self.fromLabel = fromLabel
		self.toLabel = toLabel
	}

	public var switched: Bool { !plan.isEmpty }

	public static func make(
		requestedDirection: SpaceSwitchDirection, effectiveDirection: SpaceSwitchDirection, info: SpaceInfo?,
		wrapAround: Bool
	) -> SpaceSwitchResult {
		let plan = SpaceSwitchPlan.make(direction: effectiveDirection, info: info, wrapAround: wrapAround)
		let targetIndex: Int?
		if let info, !plan.isEmpty {
			targetIndex = plan.reduce(info.currentIndex) { index, direction in
				let next = index + direction.rawValue
				return (next + info.spaceCount) % info.spaceCount
			}
		} else {
			targetIndex = nil
		}
		return SpaceSwitchResult(
			requestedDirection: requestedDirection,
			effectiveDirection: effectiveDirection,
			plan: plan,
			fromIndex: info?.currentIndex,
			toIndex: targetIndex,
			spaceCount: info?.spaceCount,
			fromLabel: info?.currentLabel,
			toLabel: targetIndex.flatMap { info?.label(at: $0) }
		)
	}
}

public struct DesktopSwitchOverlayModel: Equatable, Sendable {
	public let title: String
	public let subtitle: String
	public let selectedIndex: Int
	public let totalCount: Int

	public init(result: SpaceSwitchResult) {
		if let toIndex = result.toIndex, let spaceCount = result.spaceCount {
			title = result.toLabel ?? "Desktop \(toIndex + 1)"
			subtitle = "\(toIndex + 1) of \(spaceCount)"
			selectedIndex = toIndex + 1
			totalCount = spaceCount
		} else if !result.switched,
			let fromIndex = result.fromIndex,
			let spaceCount = result.spaceCount,
			let fromLabel = result.fromLabel
		{
			title = fromLabel
			subtitle = "\(fromIndex + 1) of \(spaceCount)"
			selectedIndex = fromIndex + 1
			totalCount = spaceCount
		} else {
			title = result.effectiveDirection == .right ? "Next Desktop" : "Previous Desktop"
			subtitle = result.switched ? "Switching Spaces" : "Desktop boundary"
			selectedIndex = 1
			totalCount = 1
		}
	}
}

private enum EventField {
	static let eventType = field(55)
	static let gestureHIDType = field(110)
	static let gestureSwipeMotion = field(123)
	static let gestureSwipeProgress = field(124)
	static let gestureSwipeVelocityX = field(129)
	static let gestureSwipeVelocityY = field(130)
	static let gesturePhase = field(132)

	private static func field(_ rawValue: UInt32) -> CGEventField {
		guard let field = CGEventField(rawValue: rawValue) else {
			preconditionFailure("Invalid CGEventField raw value \(rawValue)")
		}
		return field
	}
}

private let kCGSEventDockControl: UInt32 = 30
private let kIOHIDEventTypeDockSwipe: UInt32 = 23
private let kCGGestureMotionHorizontal: UInt16 = 1

struct SpaceSwipePayload: Sendable {
	let phase: GesturePhase
	let progress: Double
	let velocityX: Double
	let velocityY: Double

	init(phase: GesturePhase, direction: SpaceSwitchDirection, velocity: Double) {
		let sign = direction == .right ? 1.0 : -1.0

		self.phase = phase
		self.progress = sign * Double(Float.leastNonzeroMagnitude)
		self.velocityX = sign * velocity
		self.velocityY = sign * velocity
	}
}

struct SpaceSwipeFrame: Equatable, Sendable {
	let phase: GesturePhase
	let progress: Double
	let velocityX: Double
	let velocityY: Double
	let delay: Double
}

enum SpaceSwipeSequence {
	static func make(
		direction: SpaceSwitchDirection, animateScroll: Bool, animatedVelocity: Double, instantVelocity: Double
	) -> [SpaceSwipeFrame] {
		if !animateScroll {
			return [
				frame(
					phase: .began, direction: direction,
					progressMagnitude: Double(Float.leastNonzeroMagnitude),
					velocity: instantVelocity, delay: 0),
				frame(
					phase: .changed, direction: direction,
					progressMagnitude: Double(Float.leastNonzeroMagnitude),
					velocity: instantVelocity, delay: 0),
				frame(
					phase: .ended, direction: direction,
					progressMagnitude: Double(Float.leastNonzeroMagnitude),
					velocity: instantVelocity, delay: 0),
			]
		}

		let changedProgress: [Double] = [0.16, 0.32, 0.48, 0.64, 0.80, 0.96]
		var frames: [SpaceSwipeFrame] = [
			frame(
				phase: .began, direction: direction, progressMagnitude: 0, velocity: animatedVelocity,
				delay: 0)
		]

		for (index, progress) in changedProgress.enumerated() {
			frames.append(
				frame(
					phase: .changed,
					direction: direction,
					progressMagnitude: progress,
					velocity: animatedVelocity,
					delay: Double(index + 1) * 0.025
				))
		}

		frames.append(
			frame(
				phase: .ended, direction: direction, progressMagnitude: 1, velocity: animatedVelocity,
				delay: 0.20))
		return frames
	}

	private static func frame(
		phase: GesturePhase, direction: SpaceSwitchDirection, progressMagnitude: Double, velocity: Double,
		delay: Double
	) -> SpaceSwipeFrame {
		let sign = direction == .right ? 1.0 : -1.0
		return SpaceSwipeFrame(
			phase: phase,
			progress: sign * progressMagnitude,
			velocityX: sign * velocity,
			velocityY: sign * velocity,
			delay: delay
		)
	}
}

public struct SpaceInfo: Equatable, Sendable {
	public let currentIndex: Int
	public let spaceCount: Int
	public let currentLabel: String?
	private let spaceLabels: [String?]

	public init(currentIndex: Int, spaceCount: Int, currentLabel: String? = nil, spaceLabels: [String?] = []) {
		self.currentIndex = currentIndex
		self.spaceCount = spaceCount
		self.currentLabel = currentLabel
		self.spaceLabels = spaceLabels
	}

	public static func == (lhs: SpaceInfo, rhs: SpaceInfo) -> Bool {
		lhs.currentIndex == rhs.currentIndex
			&& lhs.spaceCount == rhs.spaceCount
			&& lhs.currentLabel == rhs.currentLabel
	}

	public static func current() -> SpaceInfo? {
		SpaceInfoProvider().current(displayID: nil)
	}

	public static func current(displayID: CGDirectDisplayID?) -> SpaceInfo? {
		SpaceInfoProvider().current(displayID: displayID)
	}

	static func fromManagedDisplaySpaces(_ displays: [[String: Any]], displayIdentifier: String) -> SpaceInfo? {
		let desktopLabels = desktopLabelsByID(from: displays)
		guard let display = displays.first(where: { $0["Display Identifier"] as? String == displayIdentifier }) else {
			return nil
		}
		guard let currentSpace = display["Current Space"] as? [String: Any], let currentID = id64(from: currentSpace) else {
			return nil
		}
		guard let spaces = display["Spaces"] as? [[String: Any]] else { return nil }
		guard let index = spaces.firstIndex(where: { id64(from: $0) == currentID }) else { return nil }
		let labels = spaces.map { space in id64(from: space).flatMap { desktopLabels[$0] } }
		return SpaceInfo(
			currentIndex: index,
			spaceCount: spaces.count,
			currentLabel: desktopLabels[currentID],
			spaceLabels: labels
		)
	}

	func label(at index: Int) -> String? {
		guard spaceLabels.indices.contains(index) else { return nil }
		return spaceLabels[index]
	}

	private static func id64(from dictionary: [String: Any]) -> UInt64? {
		if let id = dictionary["id64"] as? UInt64 {
			return id
		}
		if let id = dictionary["id64"] as? Int {
			return UInt64(id)
		}
		if let id = dictionary["id64"] as? NSNumber {
			return id.uint64Value
		}
		return nil
	}

	private static func spaceType(from dictionary: [String: Any]) -> Int? {
		if let type = dictionary["type"] as? Int {
			return type
		}
		if let type = dictionary["type"] as? UInt64 {
			return Int(type)
		}
		if let type = dictionary["type"] as? NSNumber {
			return type.intValue
		}
		return nil
	}

	private static func desktopLabelsByID(from displays: [[String: Any]]) -> [UInt64: String] {
		var labels: [UInt64: String] = [:]
		var desktopNumber = 1
		for display in displays {
			guard let spaces = display["Spaces"] as? [[String: Any]] else { continue }
			for space in spaces where spaceType(from: space) == 0 {
				if let id = id64(from: space) {
					labels[id] = "Desktop \(desktopNumber)"
				}
				desktopNumber += 1
			}
		}
		return labels
	}
}

enum SpaceSwitchPlan {
	static func make(direction: SpaceSwitchDirection, info: SpaceInfo?, wrapAround: Bool) -> [SpaceSwitchDirection]
	{
		guard let info else { return [direction] }
		guard info.spaceCount > 1 else { return [] }

		switch direction {
		case .left where info.currentIndex <= 0:
			return wrapAround ? Array(repeating: .right, count: info.spaceCount - 1) : []
		case .right where info.currentIndex >= info.spaceCount - 1:
			return wrapAround ? Array(repeating: .left, count: info.spaceCount - 1) : []
		default:
			return [direction]
		}
	}
}

public struct DesktopScrollAccumulator: Sendable {
	private var remainder: Double = 0
	private let threshold: Double

	public init(threshold: Double) {
		self.threshold = max(1, threshold)
	}

	public mutating func apply(delta: Double) -> SpaceSwitchDirection? {
		remainder += delta

		if remainder >= threshold {
			remainder = 0
			return .right
		}

		if remainder <= -threshold {
			remainder = 0
			return .left
		}

		return nil
	}

	public mutating func reset() {
		remainder = 0
	}
}

private typealias CGSConnectionID = Int32
private typealias CGSSpaceID = UInt64
private typealias CGSMainConnectionIDFunction = @convention(c) () -> CGSConnectionID
private typealias CGSGetActiveSpaceFunction = @convention(c) (CGSConnectionID) -> CGSSpaceID
private typealias CGSCopyManagedDisplaySpacesFunction = @convention(c) (CGSConnectionID, CFString?) ->
	Unmanaged<CFArray>?

private enum SkyLightSpaceSymbols {
	private nonisolated(unsafe) static let handle = dlopen(
		"/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
		RTLD_LAZY | RTLD_NODELETE
	)

	static let mainConnection: CGSMainConnectionIDFunction? = load(symbol: "CGSMainConnectionID")
	static let getActiveSpace: CGSGetActiveSpaceFunction? = load(symbol: "CGSGetActiveSpace")
	static let copyManagedDisplaySpaces: CGSCopyManagedDisplaySpacesFunction? = load(
		symbol: "CGSCopyManagedDisplaySpaces")

	private static func load<T>(symbol: String) -> T? {
		guard let handle, let ptr = dlsym(handle, symbol) else { return nil }
		return unsafeBitCast(ptr, to: T.self)
	}
}

private final class SpaceInfoProvider {
	func current(displayID: CGDirectDisplayID?) -> SpaceInfo? {
		guard let mainConnection = SkyLightSpaceSymbols.mainConnection,
			let copyManagedDisplaySpaces = SkyLightSpaceSymbols.copyManagedDisplaySpaces
		else { return nil }

		let connection = mainConnection()
		guard connection != 0 else { return nil }

		guard let displays = copyManagedDisplaySpaces(connection, nil)?.takeRetainedValue() else { return nil }
		if let displayID, let displayIdentifier = Self.displayIdentifier(for: displayID) {
			return parse(displays: displays, displayIdentifier: displayIdentifier)
		}

		guard let getActiveSpace = SkyLightSpaceSymbols.getActiveSpace else { return nil }
		let activeSpace = getActiveSpace(connection)
		guard activeSpace != 0 else { return nil }
		return parse(displays: displays, activeSpace: activeSpace)
	}

	private static func displayIdentifier(for displayID: CGDirectDisplayID) -> String? {
		guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else { return nil }
		return CFUUIDCreateString(nil, uuid) as String?
	}

	private func parse(displays: CFArray, displayIdentifier: String) -> SpaceInfo? {
		let displayCount = CFArrayGetCount(displays)
		var displayDictionaries: [[String: Any]] = []
		for displayIndex in 0..<displayCount {
			guard let displayValue = CFArrayGetValueAtIndex(displays, displayIndex) else { continue }

			let displayObject = unsafeBitCast(displayValue, to: CFTypeRef.self)
			guard CFGetTypeID(displayObject) == CFDictionaryGetTypeID() else { continue }
			if let display = displayObject as? [String: Any] {
				displayDictionaries.append(display)
			}
		}
		return SpaceInfo.fromManagedDisplaySpaces(displayDictionaries, displayIdentifier: displayIdentifier)
	}

	private func parse(displays: CFArray, activeSpace: CGSSpaceID) -> SpaceInfo? {
		let displayCount = CFArrayGetCount(displays)
		for displayIndex in 0..<displayCount {
			guard let displayValue = CFArrayGetValueAtIndex(displays, displayIndex) else { continue }

			let displayObject = unsafeBitCast(displayValue, to: CFTypeRef.self)
			guard CFGetTypeID(displayObject) == CFDictionaryGetTypeID() else { continue }
			let display = displayObject as! CFDictionary

			guard
				let spacesValue = CFDictionaryGetValue(
					display, Unmanaged.passUnretained("Spaces" as CFString).toOpaque())
			else { continue }
			let spacesObject = unsafeBitCast(spacesValue, to: CFTypeRef.self)
			guard CFGetTypeID(spacesObject) == CFArrayGetTypeID() else { continue }
			let spaces = spacesObject as! CFArray
			let spaceCount = CFArrayGetCount(spaces)

			for spaceIndex in 0..<spaceCount {
				guard let spaceValue = CFArrayGetValueAtIndex(spaces, spaceIndex) else { continue }

				let spaceObject = unsafeBitCast(spaceValue, to: CFTypeRef.self)
				guard CFGetTypeID(spaceObject) == CFDictionaryGetTypeID() else { continue }
				let space = spaceObject as! CFDictionary

				guard
					let idValue = CFDictionaryGetValue(
						space, Unmanaged.passUnretained("id64" as CFString).toOpaque())
				else { continue }
				let idObject = unsafeBitCast(idValue, to: CFTypeRef.self)
				guard CFGetTypeID(idObject) == CFNumberGetTypeID() else { continue }
				let idNumber = idObject as! CFNumber
				var id: UInt64 = 0
				if CFNumberGetValue(idNumber, .sInt64Type, &id), id == activeSpace {
					return SpaceInfo(currentIndex: spaceIndex, spaceCount: spaceCount)
				}
			}
		}

		return nil
	}
}

enum GesturePhase: UInt8, Sendable {
	case began = 1
	case changed = 2
	case ended = 4
}
