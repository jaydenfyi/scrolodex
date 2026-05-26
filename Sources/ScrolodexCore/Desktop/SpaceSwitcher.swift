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
		let effectiveDirection: SpaceSwitchDirection
		if invertDirection {
			effectiveDirection = direction == .left ? .right : .left
		} else {
			effectiveDirection = direction
		}

		let info = SpaceInfo.current()

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
			postDockSwipe(frames: frames)
		}
		Log.info(
			"switched desktop direction=%@ animate=%@ steps=%d",
			effectiveDirection == .left ? "left" : "right", String(animateScroll), plan.count)
		return result
	}

	private func postDockSwipe(frames: [SpaceSwipeFrame]) {
		for frame in frames {
			if frame.delay == 0 {
				postDockSwipe(frame: frame)
			} else {
				DispatchQueue.main.asyncAfter(deadline: .now() + frame.delay) { [weak self] in
					self?.postDockSwipe(frame: frame)
				}
			}
		}
	}

	private func postDockSwipe(frame: SpaceSwipeFrame) {
		guard let event = CGEvent(source: nil) else { return }

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
			spaceCount: info?.spaceCount
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
			title = "Desktop \(toIndex + 1)"
			subtitle = "\(toIndex + 1) of \(spaceCount)"
			selectedIndex = toIndex + 1
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

	public static func current() -> SpaceInfo? {
		SpaceInfoProvider().current()
	}
}

enum SpaceSwitchPlan {
	static func make(direction: SpaceSwitchDirection, info: SpaceInfo?, wrapAround: Bool) -> [SpaceSwitchDirection]
	{
		guard let info, info.spaceCount > 1 else { return [direction] }

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
	func current() -> SpaceInfo? {
		guard let mainConnection = SkyLightSpaceSymbols.mainConnection,
			let getActiveSpace = SkyLightSpaceSymbols.getActiveSpace,
			let copyManagedDisplaySpaces = SkyLightSpaceSymbols.copyManagedDisplaySpaces
		else { return nil }

		let connection = mainConnection()
		guard connection != 0 else { return nil }

		let activeSpace = getActiveSpace(connection)
		guard activeSpace != 0 else { return nil }

		guard let displays = copyManagedDisplaySpaces(connection, nil)?.takeRetainedValue() else { return nil }
		return parse(displays: displays, activeSpace: activeSpace)
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
